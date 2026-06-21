#!/bin/bash
# Polybar launch script — kills existing instances and starts fresh.
# Multi-monitor: one bar per connected output; the system tray is hosted only on
# the primary monitor (TRAY_MODULE=tray) so the bars don't fight over the single
# X systray selection ("Systray selection already managed" / XCB_MATCH errors).

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
