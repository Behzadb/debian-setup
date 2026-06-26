#!/bin/bash
# monitor-hotplug — re-apply the i3 monitor layout (and Polybar) when a display
# is plugged in or removed. Invoked by a udev DRM "change" event through
# monitor-hotplug.service (installed to /usr/local/bin by 01-window-manager.sh).
#
# It runs OUTSIDE any X session (root, from udev), so it discovers the running
# i3 session's DISPLAY/XAUTHORITY from /proc and re-runs the user's
# setup-monitors.sh as that user. setup-monitors.sh then relaunches Polybar, so
# the bars land on the right outputs.
set -u

# DRM emits a burst of "change" events on a single plug — coalesce them so we
# reconfigure once, after the connector has settled.
sleep 1

for pid in $(pgrep -x i3 2>/dev/null); do
    user=$(ps -o user= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -n "$user" ] || continue
    environ="/proc/$pid/environ"
    [ -r "$environ" ] || continue

    disp=$(tr '\0' '\n' < "$environ" | sed -n 's/^DISPLAY=//p'    | head -1)
    xauth=$(tr '\0' '\n' < "$environ" | sed -n 's/^XAUTHORITY=//p' | head -1)
    home=$(getent passwd "$user" | cut -d: -f6)
    [ -n "$disp" ] || continue
    [ -n "$xauth" ] || xauth="$home/.Xauthority"

    # Run the layout as the session user with its X env (HOME exported so the
    # script's ~/.config/... paths resolve correctly under `su`).
    su "$user" -c "export HOME='$home' DISPLAY='$disp' XAUTHORITY='$xauth'; \
        bash '$home/.config/i3/setup-monitors.sh' auto" >/dev/null 2>&1 || true
    break   # a laptop has one graphical session — done
done
