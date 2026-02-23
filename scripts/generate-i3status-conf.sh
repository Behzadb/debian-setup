#!/bin/bash
# generate-i3status-conf.sh - Generate optimized i3status.conf based on detected hardware
# This script intelligently detects your system hardware and generates a custom i3status configuration
# with proper formatting, thresholds, and monitoring options.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Detect network interfaces with quality checks
detect_network_interfaces() {
    local interfaces=()
    
    # Detect wireless interfaces
    if command -v iw &> /dev/null 2>&1; then
        for iface in $(iw dev 2>/dev/null | grep "Interface" | awk '{print $2}' 2>/dev/null); do
            if [ -n "$iface" ]; then
                interfaces+=("wireless:$iface")
            fi
        done
    fi
    
    # Detect ethernet/physical interfaces via ip command
    if command -v ip &> /dev/null; then
        for iface in $(ip -br link show 2>/dev/null | awk '{print $1}' | grep -v "^lo$"); do
            # Skip if already detected as wireless and virtual interfaces
            if ! [[ " ${interfaces[@]} " =~ "wireless:$iface" ]] && \
               [[ ! "$iface" =~ ^(docker|veth|br|virbr|tun|tap|vlan|dummy|wg|sit|gre) ]]; then
                # Check if interface is up or has potential
                if ip link show "$iface" 2>/dev/null | grep -q "BROADCAST\|POINTOPOINT"; then
                    interfaces+=("ethernet:$iface")
                fi
            fi
        done
    fi
    
    printf '%s\n' "${interfaces[@]}"
}

# Detect all thermal zones with labels
detect_thermal_zones() {
    local zones=()
    
    if [ -d "/sys/class/thermal" ]; then
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -f "$zone/temp" ] && [ -f "$zone/type" ]; then
                local zone_num=$(basename "$zone" | sed 's/thermal_zone//')
                local zone_type=$(cat "$zone/type" 2>/dev/null || echo "unknown")
                zones+=("$zone_num:$zone_type")
            fi
        done
    fi
    
    printf '%s\n' "${zones[@]}"
}

# Detect battery with capacity info
detect_battery() {
    if [ -d "/sys/class/power_supply" ]; then
        # Look for BAT0, BAT1, etc.
        for bat in /sys/class/power_supply/BAT*; do
            if [ -f "$bat/capacity" ]; then
                echo "yes"
                return
            fi
        done
        echo "no"
    fi
}

# Detect available disk/mount points
detect_disk_mounts() {
    local mounts=()
    
    # Check common mount points
    for mount in "/home" "/" "/var" "/boot"; do
        if mountpoint -q "$mount" 2>/dev/null; then
            local disk=$(df "$mount" | awk 'NR==2 {print $1}')
            if [ -n "$disk" ]; then
                mounts+=("$mount")
            fi
        fi
    done
    
    if [ ${#mounts[@]} -eq 0 ]; then
        mounts+=("/home")  # Default fallback
    fi
    
    printf '%s\n' "${mounts[@]}"
}

# Check for brightness control capability
has_brightness_control() {
    if ls /sys/class/backlight/*/brightness &>/dev/null 2>&1 || \
       command -v xbacklight &>/dev/null 2>&1; then
        echo "yes"
    else
        echo "no"
    fi
}

# Generate enhanced i3status configuration
generate_config() {
    local config_file="$1"
    local output_dir=$(dirname "$config_file")
    
    mkdir -p "$output_dir"
    
    # Backup existing config if present
    if [ -f "$config_file" ]; then
        local backup="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup"
        log_info "Backed up existing config: $backup"
    fi
    
    log_info "Generating optimized i3status configuration..."
    
    # Get detected values
    local has_battery=$(detect_battery)
    local interfaces=($(detect_network_interfaces))
    local zones=($(detect_thermal_zones))
    local mounts=($(detect_disk_mounts))
    local has_brightness=$(has_brightness_control)
    
    # Log detected hardware
    log_info "Hardware detection complete:"
    [ "$has_battery" = "yes" ] && log_info "  ✓ Battery detected" || log_info "  · No battery (desktop)"
    log_info "  ✓ Interfaces: ${#interfaces[@]}"
    log_info "  ✓ Thermal zones: ${#zones[@]}"
    log_info "  ✓ Disk mounts: ${#mounts[@]}"
    [ "$has_brightness" = "yes" ] && log_info "  ✓ Brightness control available" || true
    
    # Start config file
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    cat > "$config_file" << EOF
# i3status configuration file
# Auto-generated based on system hardware detection
# Last generated: $timestamp
# See https://i3wm.org/docs/i3status.html for complete documentation

general {
    colors = true
    interval = 5
    output_format = "i3bar"
    # Markup can be: "none", "pango", "json"
    markup = "pango"
}

# Define the order of displayed items
order += "disk /home"
EOF
    
    # Add disk mounts
    for mount in "${mounts[@]}"; do
        if [ "$mount" != "/home" ]; then
            echo "order += \"disk $mount\"" >> "$config_file"
        fi
    done
    
    # Add battery section if available
    if [ "$has_battery" = "yes" ]; then
        echo "order += \"battery all\"" >> "$config_file"
    fi
    
    # Add thermal zones
    if [ ${#zones[@]} -gt 0 ]; then
        for zone_spec in "${zones[@]}"; do
            IFS=':' read -r zone_num zone_type <<< "$zone_spec"
            echo "order += \"cpu_temperature $zone_num\"" >> "$config_file"
        done
    fi
    
    # Add system monitoring
    cat >> "$config_file" << 'EOF'
order += "memory"
order += "cpu_usage"
EOF
    
    # Add network interfaces
    for iface_spec in "${interfaces[@]}"; do
        IFS=':' read -r type iface <<< "$iface_spec"
        echo "order += \"$type $iface\"" >> "$config_file"
    done
    
# Add volume, brightness, and clock
    cat >> "$config_file" << 'EOF'
order += "volume master"
EOF

    if [ "$has_brightness" = "yes" ] && [ -e "/sys/class/backlight/intel_backlight/brightness" ]; then
        echo "order += \"backlight intel_backlight\"" >> "$config_file"
    fi
    
    cat >> "$config_file" << 'EOF'
order += "tztime local"

# ═══════════════════════════════════════════════════════════════════════════
#                         SECTION CONFIGURATIONS
# ═══════════════════════════════════════════════════════════════════════════

EOF
    
    # Disk configuration
    cat >> "$config_file" << 'EOF'

# Disk usage monitoring
disk "/home" {
    format = "<span color='#74c7ec'>📁 %avail</span>"
    low_threshold = 10
    threshold_type = "percentage_avail"
    format_below_threshold = "<span color='#f38ba8'>⚠️  %avail</span>"
}

EOF
    
    # Additional disk mounts
    for mount in "${mounts[@]}"; do
        if [ "$mount" != "/home" ]; then
            cat >> "$config_file" << EOF

disk "$mount" {
    format = "<span color='#74c7ec'>📁 $mount %avail</span>"
    low_threshold = 5
    threshold_type = "percentage_avail"
}
EOF
        fi
    done
    
    # Battery configuration if available
    if [ "$has_battery" = "yes" ]; then
        cat >> "$config_file" << 'EOF'

# Battery status
battery all {
    format = "%status %percentage %remaining"
    format_down = "<span color='#a6e3a1'>🔌 AC</span>"
    status_chr = "<span color='#a6e3a1'>⚡ %percentage</span>"
    status_bat = "<span color='#f9e2af'>🔋 %percentage</span>"
    status_unk = "<span color='#cba6f7'>? %percentage</span>"
    low_threshold = 15
    threshold_type = "percentage"
    last_full_capacity = true
}

EOF
    fi
    
    # Thermal zones configuration
    if [ ${#zones[@]} -gt 0 ]; then
        for zone_spec in "${zones[@]}"; do
            IFS=':' read -r zone_num zone_type <<< "$zone_spec"
            cat >> "$config_file" << EOF

# CPU temperature - $zone_type
cpu_temperature $zone_num {
    format = "<span color='#89b4fa'>🌡️  %degrees°C</span>"
    format_above_threshold = "<span color='#f38ba8'>🔥 %degrees°C</span>"
    path = "/sys/class/thermal/thermal_zone${zone_num}/temp"
    max_threshold = 85
}

EOF
        done
    fi
    
    # Memory and CPU configuration
    cat >> "$config_file" << 'EOF'

# Memory usage
memory {
    format = "<span color='#f5c2e7'>💾 %used/%total</span>"
    threshold_degraded = "15%"
    format_degraded = "<span color='#f9e2af'>⚠️  %used/%total</span>"
}

# CPU usage
cpu_usage {
    format = "<span color='#cba6f7'>📊 %usage</span>"
    degraded_threshold = 50
    format_above_degraded_threshold = "<span color='#f9e2af'>⚡ CPU: %usage</span>"
}

EOF
    
    # Network interface configurations
    for iface_spec in "${interfaces[@]}"; do
        IFS=':' read -r type iface <<< "$iface_spec"
        if [ -z "$iface" ] || [ "$iface" = "wireless" ] || [ "$iface" = "ethernet" ]; then
            # Skip malformed entries
            continue
        fi
        if [ "$type" = "ethernet" ]; then
            cat >> "$config_file" << EOF

# Ethernet interface: $iface
ethernet $iface {
    format_up = "<span color='#a6e3a1'>🌐 %ip (%speed)</span>"
    format_down = "<span color='#6c7086'>🌐 ⚠️  down</span>"
}
EOF
        elif [ "$type" = "wireless" ]; then
            cat >> "$config_file" << EOF

# Wireless interface: $iface
wireless $iface {
    format_up = "<span color='#a6e3a1'>📶 %essid %quality %ip</span>"
    format_down = "<span color='#6c7086'>📶 ⚠️  down</span>"
}
EOF
        fi
    done
    
    # Volume and brightness configuration
    cat >> "$config_file" << 'EOF'

# Audio volume
volume master {
    format = "<span color='#fab387'>🔊 %volume</span>"
    format_muted = "<span color='#6c7086'>🔇 muted</span>"
    device = "default"
    mixer = "Master"
}

EOF
    if [ "$has_brightness" = "yes" ] && [ -e "/sys/class/backlight/intel_backlight/brightness" ]; then
        cat >> "$config_file" << 'EOF'

# Screen brightness (Intel backlight)
backlight intel_backlight {
    format = "<span color='#fffba4'>☀️  %brightness</span>"
}

EOF
    fi
    
    # Clock configuration
    cat >> "$config_file" << 'EOF'

# System clock
tztime local {
    format = "<span color='#74c7ec'>🕐 %Y-%m-%d %H:%M:%S</span>"
}

# Useful references:
# - Colors: Use hex codes or standard X11 color names
# - Format codes: https://i3wm.org/docs/i3status.html
# - Pango markup: <span color='#rrggbb'>text</span>
# - Icons: Use Unicode/emoji for visual indicators
EOF
    
    log_info "Configuration generated: $config_file"
}

# Validate generated configuration
validate_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not created"
        return 1
    fi
    
    if ! grep -q "general {" "$config_file"; then
        log_error "Invalid configuration structure"
        return 1
    fi
    
    log_info "Configuration validation: PASSED"
    return 0
}

# Main execution
log_section "i3status Configuration Generator"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_DIR/config/i3/i3status.conf"

log_info "Detecting system hardware..."
echo ""

generate_config "$CONFIG_FILE"

if validate_config "$CONFIG_FILE"; then
    echo ""
    log_info "✓ i3status.conf generated successfully"
    log_info "Location: $CONFIG_FILE"
    echo ""
    log_info "File statistics:"
    echo "  - Lines: $(wc -l < "$CONFIG_FILE")"
    echo "  - Size: $(du -h "$CONFIG_FILE" | awk '{print $1}')"
    echo ""
    log_info "The configuration is ready to use!"
    echo ""
else
    log_error "Configuration validation failed"
    exit 1
fi
