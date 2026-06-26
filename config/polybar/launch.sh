#!/bin/bash
# Polybar launch script — kills existing instances and starts fresh.
# Multi-monitor: one bar per connected output; the system tray is hosted only on
# the primary monitor (TRAY_MODULE=tray) so the bars don't fight over the single
# X systray selection ("Systray selection already managed" / XCB_MATCH errors).

# Serialize concurrent launches. i3's `exec_always`, the Super+Shift+N keybind,
# and the monitor-hotplug service can all fire this at once; without a lock they
# interleave the kill/spawn and leave DUPLICATE bars. flock makes them run one
# after another so the last invocation produces exactly one bar per output.
# Fixed per-user path (NOT $XDG_RUNTIME_DIR — that differs between the interactive
# session and the su-invoked hotplug service, which would defeat the lock).
exec 9>"/tmp/polybar-launch-$(id -u).lock"
flock -w 15 9 || exit 0

# Stop any running polybar and WAIT until they're really gone — a fixed sleep
# races the systray release and causes the "already managed" tray error on relaunch.
if command -v polybar-msg >/dev/null 2>&1; then
    polybar-msg cmd quit >/dev/null 2>&1 || true
fi
pkill -x polybar 2>/dev/null || true
for _ in $(seq 1 20); do
    pgrep -x polybar >/dev/null 2>&1 || break
    sleep 0.2
done

# Launch a bar on each connected monitor; tray only on the primary.
if command -v xrandr >/dev/null 2>&1; then
    primary=$(xrandr --query | grep " connected primary" | cut -d" " -f1)
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        if [ "$m" = "$primary" ] || [ -z "$primary" ]; then
            MONITOR="$m" TRAY_MODULE=tray polybar --reload main &
            primary="$m"   # if xrandr reported no primary, claim the first output
        else
            MONITOR="$m" TRAY_MODULE= polybar --reload main &
        fi
    done
else
    TRAY_MODULE=tray polybar --reload main &
fi

echo "Polybar launched"
