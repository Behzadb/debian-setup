#!/bin/bash
# setup-monitors.sh - Configure monitors with xrandr and i3
# Supports home and office setups with automatic detection

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Detect connected monitors.
# IMPORTANT: only the bare monitor names go to stdout (so callers can do
# `monitors=($(detect_monitors))`). All human-readable output goes to stderr.
detect_monitors() {
    log_section "Detecting Connected Monitors" >&2

    if ! command -v xrandr &> /dev/null; then
        log_error "xrandr not found. Install: sudo apt-get install x11-xserver-utils" >&2
        exit 1
    fi

    # Get connected monitors
    local connected_monitors=$(xrandr | grep " connected" | awk '{print $1}')
    local disconnected_monitors=$(xrandr | grep " disconnected" | awk '{print $1}')

    {
        echo "Connected monitors:"
        xrandr | grep " connected" | awk '{print "  - " $1 " (" $3 ")"}'
        echo ""
        if [ -n "$disconnected_monitors" ]; then
            echo "Disconnected monitors:"
            echo "$disconnected_monitors" | awk '{print "  - " $0}'
            echo ""
        fi
    } >&2

    printf '%s\n' $connected_monitors
}

# Auto-detect and configure monitors
auto_configure() {
    log_section "Auto-Configuring Monitors"
    
    local monitors=($(xrandr | grep " connected" | awk '{print $1}'))
    local count=${#monitors[@]}
    
    log_info "Detected $count monitor(s)"
    
    if [ $count -eq 0 ]; then
        log_error "No connected monitors found"
        exit 1
    elif [ $count -eq 1 ]; then
        # Single monitor - enable it and disable others
        local monitor=${monitors[0]}
        log_info "Single monitor setup: $monitor"
        xrandr --output "$monitor" --auto --primary
        
        # Disable other outputs
        xrandr | grep " connected\|disconnected" | awk '{print $1}' | while read output; do
            if [ "$output" != "$monitor" ]; then
                xrandr --output "$output" --off
            fi
        done
    else
        # Multiple monitors - arrange them
        log_info "Multi-monitor setup detected"
        
        # Default: arrange left-right (extendright)
        local primary=${monitors[0]}
        local secondary=${monitors[1]}
        
        log_info "Primary: $primary"
        log_info "Secondary: $secondary (right of primary)"
        
        # Enable primary
        xrandr --output "$primary" --auto --primary
        
        # Enable secondary to the right
        xrandr --output "$secondary" --auto --right-of "$primary"
        
        # Disable remaining monitors
        if [ $count -gt 2 ]; then
            for i in {2..9}; do
                if [ -n "${monitors[$i]}" ]; then
                    xrandr --output "${monitors[$i]}" --off
                fi
            done
        fi
    fi
    
    log_info "Monitor configuration complete"
}

# Interactive monitor configuration
interactive_config() {
    log_section "Interactive Monitor Configuration"
    
    local monitors=($(detect_monitors))
    
    if [ ${#monitors[@]} -eq 1 ]; then
        log_info "Only one monitor detected, enabling it..."
        xrandr --output "${monitors[0]}" --auto --primary
        return
    fi
    
    echo "Available monitors: ${monitors[*]}"
    echo ""
    echo "Configuration options:"
    echo "  1. Extend right (primary | secondary)"
    echo "  2. Extend left (secondary | primary)"
    echo "  3. Extend above (primary above secondary)"
    echo "  4. Extend below (primary below secondary)"
    echo "  5. Mirror displays (clone)"
    echo "  6. Custom xrandr command"
    echo ""
    read -p "Choose option [1-6]: " choice
    
    case "$choice" in
        1)
            xrandr --output "${monitors[0]}" --auto --primary --output "${monitors[1]}" --auto --right-of "${monitors[0]}"
            log_info "Extended right"
            ;;
        2)
            xrandr --output "${monitors[0]}" --auto --primary --output "${monitors[1]}" --auto --left-of "${monitors[0]}"
            log_info "Extended left"
            ;;
        3)
            xrandr --output "${monitors[0]}" --auto --primary --output "${monitors[1]}" --auto --above "${monitors[0]}"
            log_info "Extended above"
            ;;
        4)
            xrandr --output "${monitors[0]}" --auto --primary --output "${monitors[1]}" --auto --below "${monitors[0]}"
            log_info "Extended below"
            ;;
        5)
            xrandr --output "${monitors[0]}" --auto --same-as "${monitors[1]}"
            log_info "Mirroring displays"
            ;;
        6)
            read -p "Enter xrandr command: " cmd
            eval "$cmd"
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Save current configuration
save_config() {
    local profile_name=$1
    local config_dir="$HOME/.config/i3/monitor-profiles"
    
    mkdir -p "$config_dir"
    
    local xrandr_output=$(xrandr --current)
    echo "$xrandr_output" > "$config_dir/${profile_name}.xrandr"
    
    log_info "Saved profile: $profile_name"
    log_info "Location: $config_dir/${profile_name}.xrandr"
}

# Load saved configuration
load_config() {
    local profile_name=$1
    local config_dir="$HOME/.config/i3/monitor-profiles"
    local config_file="$config_dir/${profile_name}.xrandr"
    
    if [ ! -f "$config_file" ]; then
        log_error "Profile not found: $profile_name"
        return 1
    fi
    
    log_info "Loading profile: $profile_name"
    
    # Extract xrandr commands from saved config
    # This is a basic approach - for production, use xrandr-related tools
    grep "connected" "$config_file" | while read line; do
        local monitor=$(echo "$line" | awk '{print $1}')
        local status=$(echo "$line" | awk '{print $2}')
        
        if [ "$status" = "connected" ]; then
            xrandr --output "$monitor" --auto
        else
            xrandr --output "$monitor" --off
        fi
    done
    
    log_info "Profile loaded"
}

# List saved profiles
list_profiles() {
    local config_dir="$HOME/.config/i3/monitor-profiles"
    
    if [ ! -d "$config_dir" ]; then
        log_warn "No profiles found"
        return
    fi
    
    log_section "Saved Profiles"
    ls -1 "$config_dir"/*.xrandr 2>/dev/null | xargs -I {} basename {} .xrandr || log_warn "No profiles"
}

# Main
case "${1:-auto}" in
    auto)
        auto_configure
        ;;
    interactive|i)
        interactive_config
        ;;
    detect)
        detect_monitors
        ;;
    save)
        if [ -z "$2" ]; then
            read -p "Profile name: " profile_name
        else
            profile_name="$2"
        fi
        save_config "$profile_name"
        ;;
    load)
        if [ -z "$2" ]; then
            list_profiles
            read -p "Profile name: " profile_name
        else
            profile_name="$2"
        fi
        load_config "$profile_name"
        ;;
    list)
        list_profiles
        ;;
    *)
        echo "Monitor Setup Utility"
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  auto              Auto-detect and configure monitors"
        echo "  interactive       Interactive configuration menu"
        echo "  detect            List connected monitors"
        echo "  save [name]       Save current configuration as profile"
        echo "  load [name]       Load a saved profile"
        echo "  list              List all saved profiles"
        echo ""
        echo "Examples:"
        echo "  $0 auto              # Auto-configure monitors"
        echo "  $0 interactive       # Interactive setup"
        echo "  $0 save home         # Save current setup as 'home'"
        echo "  $0 load office       # Load 'office' profile"
        exit 1
        ;;
esac

log_section "Done"
log_info "Current monitor layout:"
xrandr | grep -E "^[^ ].*connected" | awk '{printf "  %s\n", $0}'
