#!/bin/bash
# 04-power-management.sh - Power management and thermal optimization

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root"
    exit 1
fi

log_info "Starting power management setup..."

# 1. Install power management tools
log_info "Installing power management tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    tlp \
    tlp-rdw \
    powertop \
    acpi \
    acpid


# 2. Install thermal management
log_info "Installing thermal management..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    thermald

# 3. Detect and install CPU-specific tools
log_info "Configuring CPU frequency scaling..."

# Check for Intel vs AMD
# if grep -q "GenuineIntel" /proc/cpuinfo; then
#     log_info "Intel CPU detected - installing intel-pstate driver"
#     DEBIAN_FRONTEND=noninteractive apt-get install -y -qq intel-pstate
#     # intel-pstate is built-in to modern kernels
# elif grep -q "AuthenticAMD" /proc/cpuinfo; then
#     log_info "AMD CPU detected - cpufreq driver will be used"
#     # AMD uses acpi-cpufreq driver (built-in)
# fi

# 4. Configure TLP
log_info "Configuring TLP power management..."

if [ ! -f /etc/tlp.conf.bak ]; then
    cp /etc/tlp.conf /etc/tlp.conf.bak
fi

# Create TLP configuration for balanced power/performance
if [ ! -f /etc/tlp.d/debian-setup.conf ]; then
    cat > /etc/tlp.d/debian-setup.conf << 'EOF'
# TLP Configuration for productive development environment
# Balances power efficiency with performance needs

# CPU scaling - balance performance and power
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

# Disk spindown timeout
DISK_SPINDOWN_TIMEOUT_ON_AC="15"
DISK_SPINDOWN_TIMEOUT_ON_BAT="5"

# USB power management
USB_AUTOSUSPEND=1
USB_AUTOSUSPEND_USBHID=1

# PCIe ASPM (Active State Power Management)
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersave

# NMI watchdog (disable for power saving)
NMI_WATCHDOG=0

# Battery charge thresholds (ThinkPad/System76 specific)
START_CHARGE_THRESH_BAT0=20
STOP_CHARGE_THRESH_BAT0=80

# Bluetooth power management
DEVICES_TO_DISABLE_ON_BAT="bluetooth"
DEVICES_TO_ENABLE_ON_AC="bluetooth"

# WiFi power management
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Runtime power management
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto
EOF
    log_info "TLP configuration created"
fi

# 5. Enable and start power management services
log_info "Enabling power management services..."

systemctl enable tlp > /dev/null 2>&1 || true
systemctl enable tlp-sleep > /dev/null 2>&1 || true
systemctl mask systemd-rfkill > /dev/null 2>&1 || true
systemctl mask systemd-rfkill.socket > /dev/null 2>&1 || true

systemctl restart tlp > /dev/null 2>&1 || true

# 6. Enable thermal management
log_info "Enabling thermal daemon..."
systemctl enable thermald > /dev/null 2>&1 || true
systemctl restart thermald > /dev/null 2>&1 || true

# 7. Configure ACPI events for power button
log_info "Configuring ACPI power events..."

if [ -f /etc/acpi/events/powerbtn ]; then
    if ! grep -q "action=/etc/acpi/actions/powerbtn.sh" /etc/acpi/events/powerbtn; then
        sed -i 's|action=.*|action=/etc/acpi/actions/powerbtn.sh|' /etc/acpi/events/powerbtn
    fi
fi

systemctl enable acpid > /dev/null 2>&1 || true
systemctl restart acpid > /dev/null 2>&1 || true

# 8. Enable CPU frequency scaling
log_info "Verifying CPU frequency scaling..."

# Check current governors
if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
    log_info "CPU frequency scaling available"
    
    # Try to set schedutil governor (modern, power-aware)
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -w "$cpu" ]; then
            if grep -q schedutil /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null; then
                echo "schedutil" > "$cpu" 2>/dev/null || true
            else
                echo "powersave" > "$cpu" 2>/dev/null || true
            fi
        fi
    done
fi

# 9. Install optional GUI for power management
log_info "Installing optional power management tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    xfce4-power-manager-plugins \
    power-profiles-daemon

# 10. Create power profile shortcuts
log_info "Setting up power profiles..."
mkdir -p /etc/systemd/system-sleep

if [ ! -f /etc/systemd/system-sleep/powersave ]; then
    cat > /etc/systemd/system-sleep/powersave << 'EOF'
#!/bin/bash
# Run on resume
if [ "$1" = "post" ] && [ "$2" = "resume" ]; then
    echo "Resuming from sleep - restoring power profile"
    tlp start 2>/dev/null || true
fi
EOF
    chmod +x /etc/systemd/system-sleep/powersave
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_info "Power management setup completed!"
log_info "Current CPU scaling governor:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Not available"

log_warn "Post-setup recommendations:"
log_warn "  1. Check battery status: acpi -b"
log_warn "  2. View power usage: sudo powertop --calibrate"
log_warn "  3. Monitor thermal state: watch -n1 'sensors'"
log_warn "  4. For laptop: configure battery charge thresholds in TLP config"
log_warn "  5. Review TLP status: sudo tlp-stat -p"
