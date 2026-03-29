#!/bin/sh
# .xinitrc - X11 startup file
# Starts i3 window manager (invoked by: startx)

# Merge Xresources if present (e.g. DPI, font settings)
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# Set keyboard repeat: 300ms delay, 50/s repeat rate
xset r rate 300 50 2>/dev/null || true

# Start i3 window manager (picom/polybar/dunst are started by i3 config)
exec i3
