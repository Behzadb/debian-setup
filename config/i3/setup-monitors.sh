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

# Set a sensible global DPI from a monitor's physical size — ONLY when clearly
# HiDPI, so normal (~96 DPI) screens are left untouched. X11 has one global DPI,
# so on mixed-DPI setups this scales to the primary. Override in ~/.Xresources.
_apply_dpi() {
    local mon="$1" pxw="$2" phys mmw dpi target
    phys=$(xrandr | grep -E "^${mon} connected" | grep -oE '[0-9]+mm x [0-9]+mm' | head -1 || true)
    mmw=${phys%%mm*}
    { [[ "$mmw" =~ ^[0-9]+$ ]] && [ "${mmw:-0}" -gt 0 ] && [[ "$pxw" =~ ^[0-9]+$ ]]; } || return 0
    dpi=$(( pxw * 254 / (mmw * 10) ))
    if   [ "$dpi" -ge 200 ]; then target=192
    elif [ "$dpi" -ge 168 ]; then target=144
    else return 0   # ~standard density: keep default 96 (don't surprise the user)
    fi
    log_info "HiDPI primary (~${dpi} DPI) -> Xft.dpi=${target}"
    printf 'Xft.dpi: %s\n' "$target" | xrdb -merge 2>/dev/null || true
    xrandr --dpi "$target" 2>/dev/null || true
}

# Auto-detect and configure monitors OPTIMALLY:
#   - each monitor at its native resolution (mixed sizes are fine)
#   - laid out left->right, VERTICALLY CENTERED so the cursor crosses cleanly
#     even when monitors differ in height (no dead-zone)
#   - primary = the (largest) external when docked, else the internal panel
#   - HiDPI primary -> a sane global DPI so text isn't tiny
auto_configure() {
    log_section "Auto-Configuring Monitors"

    local connected
    mapfile -t connected < <(xrandr | awk '/ connected/{print $1}')
    local count=${#connected[@]}
    log_info "Detected ${count} connected monitor(s)"
    [ "$count" -eq 0 ] && { log_error "No connected monitors found"; exit 1; }

    # Native (preferred) resolution per output = first mode line listed
    declare -A W H
    local m geo maxh=0
    for m in "${connected[@]}"; do
        geo=$(xrandr | awk -v o="$m" '$1==o{f=1;next} f&&/^[[:space:]]+[0-9]+x[0-9]+/{print $1; exit}')
        W[$m]=${geo%x*}; H[$m]=${geo#*x}
        { [[ "${W[$m]}" =~ ^[0-9]+$ ]] && [[ "${H[$m]}" =~ ^[0-9]+$ ]]; } || { W[$m]=1920; H[$m]=1080; }
        [ "${H[$m]}" -gt "$maxh" ] && maxh=${H[$m]}
    done

    # Anything disconnected gets switched off
    local d off_args=()
    for d in $(xrandr | awk '/ disconnected/{print $1}'); do off_args+=(--output "$d" --off); done

    if [ "$count" -eq 1 ]; then
        m="${connected[0]}"
        xrandr --output "$m" --auto --primary "${off_args[@]}"
        log_info "Single monitor: $m at ${W[$m]}x${H[$m]}"
        _apply_dpi "$m" "${W[$m]}"
        return
    fi

    # Primary = largest external (docked work happens on the big screen); else internal
    local internal="" externals=() primary="" maxw=0
    for m in "${connected[@]}"; do
        case "$m" in
            eDP*|LVDS*|DSI*) internal="$m" ;;
            *)               externals+=("$m") ;;
        esac
    done
    if [ ${#externals[@]} -gt 0 ]; then
        for m in "${externals[@]}"; do
            [ "${W[$m]}" -gt "$maxw" ] && { maxw=${W[$m]}; primary="$m"; }
        done
    else
        primary="$internal"
    fi
    [ -z "$primary" ] && primary="${connected[0]}"

    # Order: internal on the left, externals to the right (predictable)
    local order=()
    [ -n "$internal" ] && order+=("$internal")
    for m in "${externals[@]}"; do order+=("$m"); done
    [ ${#order[@]} -eq 0 ] && order=("${connected[@]}")

    # One atomic xrandr: native mode, left->right, vertically centered
    local args=() x=0 y
    for m in "${order[@]}"; do
        y=$(( (maxh - H[$m]) / 2 ))
        args+=(--output "$m" --mode "${W[$m]}x${H[$m]}" --pos "${x}x${y}")
        [ "$m" = "$primary" ] && args+=(--primary)
        x=$(( x + W[$m] ))
    done

    if xrandr "${args[@]}" "${off_args[@]}"; then
        log_info "Arranged: ${order[*]} (left->right, vertically centered); primary=$primary"
    else
        log_warn "xrandr layout failed -- falling back to --auto --right-of"
        xrandr --output "${order[0]}" --auto --primary
        local prev="${order[0]}"
        for m in "${order[@]:1}"; do xrandr --output "$m" --auto --right-of "$prev"; prev="$m"; done
    fi
    _apply_dpi "$primary" "${W[$primary]}"
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
