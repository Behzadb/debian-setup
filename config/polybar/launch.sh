#!/bin/bash
# Polybar launch script - kills existing instances and starts fresh
# Supports multi-monitor: launches a bar on each connected output

# Kill existing polybar instances
pkill -x polybar 2>/dev/null || true

# Wait for processes to die
sleep 0.5

# Launch polybar on all connected monitors
if type "xrandr" > /dev/null 2>&1; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload main &
    done
else
    polybar --reload main &
fi

echo "Polybar launched"
