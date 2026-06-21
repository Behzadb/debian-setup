#!/bin/bash
# Polybar launch script - kills existing instances and starts fresh
# Supports multi-monitor: launches a bar on each connected output

# Kill existing polybar instances
pkill -x polybar 2>/dev/null || true

# Wait for processes to die
sleep 0.5

# Launch polybar on all connected monitors.
# Only the primary monitor gets the system tray (TRAY_POSITION=right); others
# launch with an empty TRAY_POSITION so they don't fight over the single tray.
if type "xrandr" > /dev/null 2>&1; then
    primary=$(xrandr --query | grep " connected primary" | cut -d" " -f1)
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        if [ "$m" = "$primary" ] || [ -z "$primary" ]; then
            MONITOR=$m TRAY_POSITION=right polybar --reload main &
            primary="$m"   # if no primary was set, claim the first monitor
        else
            MONITOR=$m TRAY_POSITION= polybar --reload main &
        fi
    done
else
    TRAY_POSITION=right polybar --reload main &
fi

echo "Polybar launched"
