#!/bin/bash
# 04-power-management.sh - Power management and thermal optimization
# Configures TLP for balanced power/performance on laptops and desktops.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# Detect hardware that supports battery charge threshold management.
# ThinkPad, System76, and TUXEDO laptops expose these via TLP.
# On other hardware TLP would log warnings about unsupported settings.
_supports_battery_thresh() {
    local family vendor
    family="$(cat /sys/class/dmi/id/product_family 2>/dev/null || echo '')"
    vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo '')"
    [[ "$family" == *"ThinkPad"* || "$vendor" == *"System76"* || "$vendor" == *"TUXEDO"* ]]
}

if [[ -f /etc/tlp.conf && ! -f /etc/tlp.conf.bak ]]; then
    cp /etc/tlp.conf /etc/tlp.conf.bak
fi

# Create base TLP configuration for balanced power/performance
if [[ ! -f /etc/tlp.d/debian-setup.conf ]]; then
    mkdir -p /etc/tlp.d
    cat > /etc/tlp.d/debian-setup.conf << 'EOF'
# TLP Configuration — debian-setup
# Balances power efficiency with performance for development workloads

# CPU scaling
CPU_SCALING_GOVERNOR_ON_AC=schedutil
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU frequency limits (0 = no limit)
CPU_SCALING_MIN_FREQ_ON_AC=800000
CPU_SCALING_MAX_FREQ_ON_AC=0
CPU_SCALING_MIN_FREQ_ON_BAT=800000
CPU_SCALING_MAX_FREQ_ON_BAT=2400000

# Turbo boost (1=enabled, 0=disabled)
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Disk power management
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
DISK_SPINDOWN_TIMEOUT_ON_AC="15"
DISK_SPINDOWN_TIMEOUT_ON_BAT="5"

# USB power management
USB_AUTOSUSPEND=1
USB_AUTOSUSPEND_USBHID=1

# PCIe ASPM
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersave

# NMI watchdog (disable for power saving)
NMI_WATCHDOG=0

# Bluetooth on battery
DEVICES_TO_DISABLE_ON_BAT="bluetooth"
DEVICES_TO_ENABLE_ON_AC="bluetooth"

# WiFi power management
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Runtime power management
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto
EOF

    # Battery charge thresholds — only supported on ThinkPad, System76, TUXEDO.
    # Writing these on unsupported hardware causes TLP to log errors on every boot.
    if _supports_battery_thresh; then
        log_info "ThinkPad/System76/TUXEDO detected — enabling battery charge thresholds"
        cat >> /etc/tlp.d/debian-setup.conf << 'EOF'

# Battery charge thresholds (ThinkPad/System76/TUXEDO only)
# Limits charge to 20–80% to extend long-term battery health.
START_CHARGE_THRESH_BAT0=20
STOP_CHARGE_THRESH_BAT0=80
EOF
    else
        log_info "Hardware does not support charge thresholds — skipping (ThinkPad/System76/TUXEDO only)"
    fi

    log_success "TLP configuration created"
else
    log_info "TLP configuration already exists"
fi

# 4. Enable services
log_info "Enabling power management services..."
enable_service tlp
systemctl enable tlp-sleep > /dev/null 2>&1 || true

# Do NOT mask systemd-rfkill. Masking it stops the radio (Wi-Fi/Bluetooth)
# soft-block state from being saved and restored across reboots. TLP only needs
# systemd-rfkill masked when it manages startup radio state itself
# (RESTORE_DEVICE_STATE_ON_STARTUP=1), which this setup does NOT enable — the
# debian-setup TLP profile only switches Bluetooth at runtime by power source
# (DEVICES_TO_DISABLE_ON_BAT), which does not conflict with systemd-rfkill.
# Unmask it here so machines provisioned by earlier versions of this script
# regain working rfkill persistence.
if systemctl is-enabled systemd-rfkill 2>/dev/null | grep -q masked; then
    log_info "Unmasking systemd-rfkill (restores Wi-Fi/Bluetooth state persistence)..."
    systemctl unmask systemd-rfkill > /dev/null 2>&1 || true
    systemctl unmask systemd-rfkill.socket > /dev/null 2>&1 || true
fi

restart_service tlp

# 5. Thermal daemon
log_info "Enabling thermal daemon..."
enable_service thermald
restart_service thermald

# 6. ACPI events
log_info "Configuring ACPI power events..."
if [[ -f /etc/acpi/events/powerbtn ]]; then
    if ! grep -q "action=/etc/acpi/actions/powerbtn.sh" /etc/acpi/events/powerbtn 2>/dev/null; then
        sed -i 's|action=.*|action=/etc/acpi/actions/powerbtn.sh|' /etc/acpi/events/powerbtn
    fi
fi
enable_service acpid
restart_service acpid

# 7. CPU frequency scaling verification
log_info "Verifying CPU frequency scaling..."
if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
    log_info "CPU frequency scaling available"
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -w "$cpu" ]]; then
            if grep -q schedutil /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null; then
                echo "schedutil" > "$cpu" 2>/dev/null || true
            fi
        fi
    done
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

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_section "Power Management Complete"
log_info "Current governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
log_warn "Recommendations:"
log_warn "  1. Battery status: acpi -b"
log_warn "  2. Power usage: sudo powertop --calibrate"
log_warn "  3. Thermal: watch -n1 'sensors'"
log_warn "  4. TLP status: sudo tlp-stat -p"
