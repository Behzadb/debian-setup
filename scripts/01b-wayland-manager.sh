#!/bin/bash
# 01b-wayland-manager.sh - Install and configure Sway Wayland compositor
# A robust, modern replacement for i3 + X11.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

require_root

log_section "Wayland Window Manager Installation (Sway)"

# 1. Base Wayland & Sway
log_info "Installing Sway compositor..."
ensure_pkgs \
    sway \
    swaybg \
    swayidle \
    swaylock \
    wayland-protocols \
    xwayland \
    xdg-desktop-portal-wlr

# 2. Modern Wayland alternatives
log_info "Installing Wayland-native utilities..."
ensure_pkgs \
    waybar \
    wofi \
    mako-notifier \
    grim \
    slurp \
    wl-clipboard

# 3. Terminals
log_info "Installing terminal emulators..."
ensure_pkgs kitty alacritty

# 4. Fonts
log_info "Installing fonts..."
ensure_pkgs \
    fonts-dejavu \
    fonts-liberation \
    fontconfig

install_nerd_font "FiraCode" "FiraCode"
install_nerd_font "JetBrainsMono" "JetBrainsMono"

# 5. Brightness and Audio
log_info "Installing hardware control tools..."
ensure_pkgs brightnessctl

if pkg_installed pipewire || apt-cache show pipewire-audio >/dev/null 2>&1; then
    log_info "Installing PipeWire standard..."
    ensure_pkgs \
        pipewire-audio \
        pipewire-pulse \
        wireplumber 2>/dev/null || \
    ensure_pkgs \
        pipewire \
        pipewire-pulse
    systemctl --global enable pipewire.service pipewire-pulse.service 2>/dev/null || true
    systemctl --global enable wireplumber.service 2>/dev/null || true
fi

# 6. Display Manager (SDDM supports Wayland natively better than LightDM)
log_info "Installing display manager (sddm)..."
ensure_pkgs sddm
enable_service sddm

log_info "Disabling LightDM if active so SDDM can take over..."
systemctl disable lightdm 2>/dev/null || true

# 7. Additional dependencies for system monitoring and clipboard
ensure_pkgs btop

# 8. Utility GUI Apps
log_info "Installing utility desktop applications..."
ensure_pkgs chromium || ensure_pkgs chromium-browser || log_warn "Chromium not available"
ensure_pkgs thunar gvfs pavucontrol imv mpv

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true

log_section "Sway Setup Complete"
log_info "Desktop environment ready:"
log_info "  - Display Manager: sddm"
log_info "  - Window Manager: Sway (Wayland)"
log_info "  - Status Bar: Waybar"
log_info "  - Launcher: Wofi"
log_info "  - Screenshot: grim + slurp"
log_info "  - Clipboard: wl-clipboard"
