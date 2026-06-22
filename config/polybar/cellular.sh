#!/bin/bash
# Polybar cellular/WWAN status via ModemManager.
# Prints e.g. "LTE 72%" when connected, "LTE…" while registering; prints NOTHING
# when there is no modem, so the Polybar module hides itself on machines without
# WWAN. Read-only and fail-quiet (exits 0) if mmcli is missing or not permitted.

command -v mmcli >/dev/null 2>&1 || exit 0

idx=$(mmcli -L 2>/dev/null | grep -oE '/Modem/[0-9]+' | grep -oE '[0-9]+$' | head -1)
[ -z "$idx" ] && exit 0

info=$(mmcli -m "$idx" -K 2>/dev/null) || exit 0
get() { printf '%s\n' "$info" | sed -n "s/^$1[[:space:]]*:[[:space:]]*//p" | head -1; }

state=$(get 'modem.generic.state')
sig=$(get 'modem.generic.signal-quality.value')
tech=$(get 'modem.generic.access-technologies.value' | awk '{print toupper($1)}')

case "$state" in
    connected)                     printf '%s %s%%\n' "${tech:-LTE}" "${sig:-?}" ;;
    registered|searching|enabled)  printf '%s…\n' "${tech:-WWAN}" ;;
    *)                             exit 0 ;;
esac
