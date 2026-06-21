#!/bin/bash
# 04-power-management.sh - Power management and thermal optimization
# Configures TLP for balanced power/performance on laptops and desktops.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

require_root

log_section "Power Management Setup"

# 1. Install power management tools
log_info "Installing power management tools..."
ensure_pkgs \
    tlp \
    tlp-rdw \
    powertop \
    acpi \
    acpid

# 2. Thermal management
log_info "Installing thermal management..."
ensure_pkgs thermald || log_warn "thermald not available (may not be needed on AMD systems)"

# NOTE: Do NOT install power-profiles-daemon — it conflicts with TLP
# and will mask TLP's power management. TLP is more configurable.
if pkg_installed power-profiles-daemon; then
    log_warn "power-profiles-daemon detected — this conflicts with TLP"
    log_warn "Consider removing it: apt-get remove power-profiles-daemon"
fi

# 3. Configure TLP
log_info "Configuring TLP power management..."

if [[ -f /etc/tlp.conf && ! -f /etc/tlp.conf.bak ]]; then
    cp /etc/tlp.conf /etc/tlp.conf.bak
fi

# Create TLP configuration for balanced power/performance
if [[ ! -f /etc/tlp.d/debian-setup.conf ]]; then
    mkdir -p /etc/tlp.d
    cat > /etc/tlp.d/debian-setup.conf << 'EOF'
# TLP Configuration — debian-setup
# Tuned for ThinkPad T14 (Gen3/Gen7, both Intel and AMD variants).
#
# CPU pacing is done via the Energy-Performance-Preference (EPP/HWP) and the
# ACPI platform profile. These work with BOTH intel_pstate and amd_pstate in
# their default "active" mode — unlike fixed governors such as 'schedutil',
# which those drivers do NOT expose (only 'powersave' and 'performance' exist).

# --- CPU scaling governor ---
# 'powersave' is the correct governor for intel_pstate / amd_pstate active mode
# on AC *and* battery; the real bias comes from EPP below (it still turbos).
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# --- Energy vs performance bias (EPP) — the main battery lever ---
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# --- Turbo / boost ---
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
# Intel HWP dynamic boost (ignored on AMD)
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

# --- ACPI platform profile (ThinkPad firmware power envelope) ---
# Requires TLP >= 1.5 (Debian 12+). The 'power-profile' helper overrides these
# on demand; TLP re-applies them on the next AC/BAT change.
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power

# --- PCIe Active State Power Management ---
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersave

# --- Runtime PM for PCIe devices ---
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto

# --- SATA link power (no effect on the NVMe-only T14, harmless otherwise) ---
SATA_LINKPWR_ON_AC=max_performance
SATA_LINKPWR_ON_BAT=med_power_with_dipm

# --- WiFi power saving ---
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# --- Wake-on-LAN off (NIC needn't stay armed/powered; tiny standby saving) ---
WOL_DISABLE=Y

# --- USB autosuspend ---
# Autosuspend saves power but is a common cause of USB microphone, headset and
# webcam dropouts. Keep it on but exclude audio/bluetooth/phones. NOTE: we do
# NOT disable Bluetooth on battery (DEVICES_TO_DISABLE_ON_BAT) so BT headset
# mics keep working unplugged. If a USB webcam still disconnects mid-call, add
# its "vendor:product" (from `lsusb`) to USB_DENYLIST, e.g. "046d:0825".
USB_AUTOSUSPEND=1
USB_EXCLUDE_AUDIO=1
USB_EXCLUDE_BTUSB=1
USB_EXCLUDE_PHONE=1
USB_DENYLIST=""

# --- NMI watchdog (off saves a little power) ---
NMI_WATCHDOG=0

# --- Battery charge thresholds (ThinkPad T14: native thinkpad_acpi) ---
# Defaults balance lifespan and usable capacity. Tune to taste:
#   • MAXIMUM runtime per charge  -> STOP_CHARGE_THRESH_BAT0=100
#   • MAXIMUM lifespan (always docked) -> keep 75/80
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF
    log_success "TLP configuration created"
else
    log_info "TLP configuration already exists"
fi

# 3b. Install the situational power-profile helper + passwordless sudo rule
# (lets the i3 keybindings and Polybar switch profiles without a password).
log_info "Installing power-profile helper..."
if [[ -f "$REPO_DIR/config/power/power-profile.sh" ]]; then
    install -m 0755 -o root -g root "$REPO_DIR/config/power/power-profile.sh" /usr/local/bin/power-profile
    cat > /etc/sudoers.d/power-profile << 'EOF'
# Allow the sudo group to switch power profiles without a password
# (used by the i3 keybindings and the Polybar click action).
%sudo ALL=(root) NOPASSWD: /usr/local/bin/power-profile
EOF
    chmod 0440 /etc/sudoers.d/power-profile
    if visudo -cf /etc/sudoers.d/power-profile >/dev/null 2>&1; then
        log_success "power-profile installed → /usr/local/bin/power-profile (sudo NOPASSWD)"
    else
        log_error "Generated sudoers file is invalid — removing it"
        rm -f /etc/sudoers.d/power-profile
    fi
else
    log_warn "power-profile helper not found in repo — skipping"
fi

# 4. Enable services
log_info "Enabling power management services..."
enable_service tlp
systemctl enable tlp-sleep > /dev/null 2>&1 || true
systemctl mask systemd-rfkill > /dev/null 2>&1 || true
systemctl mask systemd-rfkill.socket > /dev/null 2>&1 || true
restart_service tlp

# 5. Thermal daemon
log_info "Enabling thermal daemon..."
enable_service thermald
restart_service thermald

# 6. ACPI daemon
# NOTE: lid-close, power-button and suspend are handled by systemd-logind
# (HandleLidSwitch=suspend / HandlePowerKey=poweroff by default) — we do NOT
# wire acpid to a custom powerbtn action (the old version pointed at a script
# that was never created). acpid is kept for battery/AC and other ACPI events.
log_info "Enabling acpid (battery/AC events)..."
enable_service acpid
restart_service acpid

# 7. CPU scaling driver report (TLP owns the governor/EPP; just report here)
log_info "Detecting CPU scaling driver..."
if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]]; then
    SCALING_DRIVER=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)
    log_info "CPU scaling driver: $SCALING_DRIVER"
    case "$SCALING_DRIVER" in
        intel_pstate) log_info "Intel P-state (T14 Intel) — EPP + platform_profile in use" ;;
        amd-pstate*)  log_info "AMD P-state (T14 AMD) — EPP + platform_profile in use" ;;
        *)            log_info "Generic cpufreq driver — governor/boost still managed by TLP" ;;
    esac
fi

# 8. Sleep/resume hook
log_info "Setting up power profiles..."
mkdir -p /etc/systemd/system-sleep

if [[ ! -f /etc/systemd/system-sleep/powersave ]]; then
    cat > /etc/systemd/system-sleep/powersave << 'EOF'
#!/bin/bash
# Resume hook — restore TLP power profile
if [ "$1" = "post" ] && [ "$2" = "resume" ]; then
    echo "Resuming from sleep — restoring power profile"
    tlp start 2>/dev/null || true
fi
EOF
    chmod +x /etc/systemd/system-sleep/powersave
fi

# 9. Reduce suspend battery drain — prefer S3 "deep" sleep when the firmware
# offers it. s2idle / "Modern Standby" can drain ~1-2%/h; S3 is ~0.3%/h.
# SAFETY: this is conditional and reversible. We do NOT touch the GRUB cmdline.
# A boot-time oneshot writes /sys/power/mem_sleep to "deep" ONLY if the firmware
# advertises it (otherwise it's a no-op), so it can't force an unsupported state.
# To revert: `sudo systemctl disable --now suspend-deep-sleep.service` and reboot.
log_info "Configuring suspend mode (S3 deep sleep when supported)..."
cat > /etc/systemd/system/suspend-deep-sleep.service << 'EOF'
[Unit]
Description=Prefer S3 deep sleep over s2idle when the firmware supports it
Documentation=https://www.kernel.org/doc/html/latest/admin-guide/pm/sleep-states.html
ConditionPathExists=/sys/power/mem_sleep

[Service]
Type=oneshot
# Only switch if "deep" is actually offered; never force an unsupported state.
ExecStart=/bin/sh -c 'grep -qw deep /sys/power/mem_sleep && echo deep > /sys/power/mem_sleep || true'

[Install]
WantedBy=multi-user.target
EOF
enable_service suspend-deep-sleep.service
# Apply now too (so the current boot benefits without a reboot)
if grep -qw deep /sys/power/mem_sleep 2>/dev/null; then
    echo deep > /sys/power/mem_sleep 2>/dev/null || true
    log_success "Suspend mode set to S3 deep sleep (lower battery drain while suspended)"
else
    log_info "Firmware only offers s2idle — leaving suspend mode unchanged (service is a safe no-op)"
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_section "Power Management Complete"
log_info "Current platform profile: $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo 'N/A')"
log_info "Current governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
log_info "Situational profiles: power-profile {performance|balanced|powersave|auto|status}"
log_info "  i3: Super+Shift+p opens the power-profile mode; Polybar shows/cycles it"
log_warn "Recommendations:"
log_warn "  1. Battery status: acpi -b"
log_warn "  2. Power usage: sudo powertop --calibrate"
log_warn "  3. Thermal: watch -n1 'sensors'"
log_warn "  4. TLP status: sudo tlp-stat -p"
log_warn "  5. Profile now: power-profile status"
