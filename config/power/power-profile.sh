#!/bin/bash
# power-profile — situational power profile switcher for ThinkPad T14 (Gen3/Gen7)
#
# Works on both Intel (intel_pstate) and AMD (amd_pstate) T14 variants. It drives
# the knobs that exist regardless of CPU vendor:
#   • the ACPI platform profile  (/sys/firmware/acpi/platform_profile)
#   • the CPU Energy-Performance-Preference (EPP/HWP)
#   • turbo / boost
#
# It is SAFE by design: it only writes to sysfs nodes that exist and are
# writable, and it validates every value against what the hardware advertises,
# so an unsupported value is skipped rather than erroring out.
#
# TLP still owns the automatic AC/BAT baseline; this helper is a manual override
# for "right now" needs. TLP re-applies its defaults on the next AC/BAT change
# (or run `power-profile auto` to re-apply them immediately).
#
# Usage: power-profile {performance|balanced|powersave|auto|status|cycle}
# Switching a profile needs root (the i3 keybindings/Polybar call it via sudo;
# see /etc/sudoers.d/power-profile).

set -u

PROG="power-profile"
PP="/sys/firmware/acpi/platform_profile"
PP_CHOICES="/sys/firmware/acpi/platform_profile_choices"
INTEL_NO_TURBO="/sys/devices/system/cpu/intel_pstate/no_turbo"
CPUFREQ_BOOST="/sys/devices/system/cpu/cpufreq/boost"

usage() {
    cat <<EOF
Usage: $PROG {performance|balanced|powersave|auto|status|cycle}

  performance  max speed     (platform=performance, EPP=performance,         turbo on)
  balanced     default       (platform=balanced,    EPP=balance_performance, turbo on)
  powersave    max battery   (platform=low-power,   EPP=power,               turbo off)
  auto         re-apply TLP's automatic AC/BAT settings (tlp start)
  status       show the current power state
  cycle        powersave -> balanced -> performance -> powersave
EOF
}

require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "$PROG: switching profiles requires root (use: sudo $PROG $*)" >&2
        exit 1
    fi
}

# Set the ACPI platform profile to the best available match for the desired level.
set_platform_profile() {
    local want="$1"
    [[ -w "$PP" ]] || return 0
    local choices candidates pick=""
    choices=$(cat "$PP_CHOICES" 2>/dev/null)
    case "$want" in
        performance) candidates="performance balanced-performance balanced" ;;
        balanced)    candidates="balanced balanced-performance" ;;
        low-power)   candidates="low-power quiet cool balanced" ;;
        *)           return 0 ;;
    esac
    local c
    for c in $candidates; do
        if printf '%s\n' $choices | grep -qx "$c"; then pick="$c"; break; fi
    done
    [[ -n "$pick" ]] && echo "$pick" > "$PP" 2>/dev/null || true
}

# Set the CPU Energy-Performance-Preference on every CPU, validating the value.
set_epp() {
    local want="$1" f avail
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        [[ -w "$f" ]] || continue
        avail=$(cat "${f%energy_performance_preference}energy_performance_available_preferences" 2>/dev/null)
        if printf '%s\n' $avail | grep -qx "$want"; then
            echo "$want" > "$f" 2>/dev/null || true
        fi
    done
}

# Turbo: $1 = on|off. intel_pstate uses no_turbo (inverted); cpufreq uses boost.
set_turbo() {
    if [[ -w "$INTEL_NO_TURBO" ]]; then
        [[ "$1" == on ]] && echo 0 > "$INTEL_NO_TURBO" 2>/dev/null || echo 1 > "$INTEL_NO_TURBO" 2>/dev/null
    elif [[ -w "$CPUFREQ_BOOST" ]]; then
        [[ "$1" == on ]] && echo 1 > "$CPUFREQ_BOOST" 2>/dev/null || echo 0 > "$CPUFREQ_BOOST" 2>/dev/null
    fi
}

apply() {
    case "$1" in
        performance) set_platform_profile performance; set_epp performance;         set_turbo on ;;
        balanced)    set_platform_profile balanced;    set_epp balance_performance; set_turbo on ;;
        powersave)   set_platform_profile low-power;   set_epp power;               set_turbo off ;;
    esac
}

status() {
    local gov epp turbo
    echo "platform profile : $(cat "$PP" 2>/dev/null || echo 'n/a')  (choices: $(cat "$PP_CHOICES" 2>/dev/null || echo 'n/a'))"
    gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'n/a')
    epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo 'n/a')
    echo "cpu governor     : $gov"
    echo "cpu EPP          : $epp"
    if [[ -r "$INTEL_NO_TURBO" ]]; then
        [[ "$(cat "$INTEL_NO_TURBO")" == 0 ]] && turbo="on" || turbo="off"
    elif [[ -r "$CPUFREQ_BOOST" ]]; then
        [[ "$(cat "$CPUFREQ_BOOST")" == 1 ]] && turbo="on" || turbo="off"
    else
        turbo="n/a"
    fi
    echo "turbo / boost    : $turbo"
    command -v acpi >/dev/null 2>&1 && echo "battery          : $(acpi -b 2>/dev/null | head -1 | sed 's/^Battery [0-9]*: //')"
}

case "${1:-status}" in
    performance|balanced|powersave)
        require_root "$1"; apply "$1"; echo "$PROG: applied '$1'" ;;
    auto)
        require_root auto
        if command -v tlp >/dev/null 2>&1; then
            tlp start >/dev/null 2>&1 && echo "$PROG: re-applied TLP AC/BAT defaults"
        else
            echo "$PROG: tlp not installed" >&2; exit 1
        fi ;;
    cycle)
        require_root cycle
        case "$(cat "$PP" 2>/dev/null)" in
            low-power|quiet|cool) apply balanced;    echo "$PROG: balanced" ;;
            balanced*)            apply performance; echo "$PROG: performance" ;;
            *)                    apply powersave;   echo "$PROG: powersave" ;;
        esac ;;
    status)
        status ;;
    -h|--help|help)
        usage ;;
    *)
        usage; exit 1 ;;
esac
