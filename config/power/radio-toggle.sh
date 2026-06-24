#!/bin/bash
# radio-toggle — quickly disable/enable wireless & wired devices to save battery
# on a ThinkPad T14 (or any laptop). Radios (WiFi/WWAN/Bluetooth) are switched
# via rfkill; wired Ethernet via NetworkManager. Changing state needs root — the
# i3 keybindings call it through passwordless sudo (see /etc/sudoers.d/radio-toggle).
# `status` works without root.
#
# Usage:
#   radio-toggle {wifi|wwan|bluetooth|eth} [on|off|toggle]   (default: toggle)
#   radio-toggle status        show the state of every device
#   radio-toggle all-off       block WiFi + WWAN + Bluetooth (max radio silence)
#   radio-toggle all-on        unblock WiFi + WWAN + Bluetooth
#
# Notes:
#   • wwan = the LTE/cellular modem (biggest idle drain when present).
#   • TLP's Radio Device Wizard may also auto-toggle these by context (e.g. drop
#     WWAN when WiFi connects); this helper is the manual "right now" override.

set -u
PROG="radio-toggle"

usage() {
    sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

need_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "$PROG: changing device state requires root (use: sudo $PROG $*)" >&2
        exit 1
    fi
}

# --- rfkill-managed radios (wifi / wwan / bluetooth) -------------------------
# Prints: on | off | n/a (n/a = no such device on this machine).
rf_state() {
    local out
    out=$(rfkill list "$1" 2>/dev/null)
    [[ -z "$out" ]] && { echo "n/a"; return; }
    if printf '%s' "$out" | grep -qi "blocked: yes"; then echo off; else echo on; fi
}

# --- wired Ethernet via NetworkManager --------------------------------------
eth_dev() {
    nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="ethernet"{print $1; exit}'
}
eth_state() {
    local d s; d=$(eth_dev); [[ -z "$d" ]] && { echo "n/a"; return; }
    s=$(nmcli -t -f DEVICE,STATE device 2>/dev/null | awk -F: -v d="$d" '$1==d{print $2}')
    [[ "$s" == connected ]] && echo on || echo off
}

print_status() {
    printf "%-11s %s\n" "wifi:"      "$(rf_state wifi)"
    printf "%-11s %s\n" "wwan:"      "$(rf_state wwan)"
    printf "%-11s %s\n" "bluetooth:" "$(rf_state bluetooth)"
    printf "%-11s %s\n" "ethernet:"  "$(eth_state)"
}

# --- dispatch ----------------------------------------------------------------
dev="${1:-status}"
act="${2:-toggle}"

case "$dev" in
    status)         print_status; exit 0 ;;
    -h|--help|help) usage; exit 0 ;;
    all-off)
        need_root "$@"
        rfkill block wifi wwan bluetooth 2>/dev/null
        echo "$PROG: wifi/wwan/bluetooth off"; exit 0 ;;
    all-on)
        need_root "$@"
        rfkill unblock wifi wwan bluetooth 2>/dev/null
        echo "$PROG: wifi/wwan/bluetooth on"; exit 0 ;;
    wifi|wlan)               ID=wifi ;;
    wwan|cellular|lte|modem) ID=wwan ;;
    bt|bluetooth)            ID=bluetooth ;;
    eth|ethernet|lan|wired)  ID=eth ;;
    *) usage; exit 1 ;;
esac

# Current state
if [[ "$ID" == eth ]]; then cur=$(eth_state); else cur=$(rf_state "$ID"); fi
if [[ "$cur" == "n/a" ]]; then
    echo "$PROG: no $dev device on this machine"; exit 0
fi

# Resolve the desired new state
case "$act" in
    on|off) new="$act" ;;
    toggle) [[ "$cur" == on ]] && new=off || new=on ;;
    *) usage; exit 1 ;;
esac

need_root "$@"
if [[ "$ID" == eth ]]; then
    d=$(eth_dev)
    if [[ "$new" == off ]]; then nmcli device disconnect "$d" >/dev/null
    else nmcli device connect "$d" >/dev/null; fi
else
    if [[ "$new" == off ]]; then rfkill block "$ID"; else rfkill unblock "$ID"; fi
fi
echo "$PROG: $dev $new"
