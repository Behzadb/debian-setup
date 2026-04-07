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
    xwayland

# xdg-desktop-portal stack:
#   xdg-desktop-portal:     base daemon — required for ALL portal backends
#   xdg-desktop-portal-wlr: screen capture (used by OBS, browser screenshare)
#   xdg-desktop-portal-gtk: mic & camera permission dialogs in Chromium/Firefox
# Both WLR and GTK backends are needed; WLR handles screen, GTK handles camera/mic.
log_info "Installing XDG desktop portal stack (screen share + camera/mic)..."
ensure_pkgs \
    xdg-desktop-portal \
    xdg-desktop-portal-wlr \
    xdg-desktop-portal-gtk || log_warn "Some portal packages unavailable"

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
    log_info "Installing PipeWire (audio + ALSA bridge)..."
    ensure_pkgs \
        pipewire-audio \
        pipewire-pulse \
        pipewire-alsa \
        wireplumber 2>/dev/null || \
    ensure_pkgs \
        pipewire \
        pipewire-pulse \
        pipewire-alsa
    systemctl --global enable pipewire.service pipewire-pulse.service 2>/dev/null || true
    systemctl --global enable wireplumber.service 2>/dev/null || true
    log_success "PipeWire audio + ALSA bridge installed"
fi

# Camera / media device support
# v4l-utils: Video4Linux2 userspace — required for webcam access in Chromium
log_info "Installing camera device support..."
ensure_pkgs v4l-utils || log_warn "v4l-utils unavailable"

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

# 8a. Chromium flags for Wayland + PipeWire camera/mic
# Without these flags Chromium falls back to X11 mode and uses XCB for media,
# bypassing PipeWire entirely — mic and camera stop working on Wayland.
CHROMIUM_FLAGS_FILE="/etc/chromium/flags"
CHROMIUM_BROWSER_FLAGS_FILE="/etc/chromium-browser/flags"

_write_chromium_flags() {
    local flags_file="$1"
    if [[ ! -f "$flags_file" ]]; then
        mkdir -p "$(dirname "$flags_file")"
        cat > "$flags_file" << 'EOF'
# Chromium flags — Wayland + PipeWire (written by debian-setup)
# Enable native Wayland rendering (no XWayland wrapper)
--ozone-platform=wayland
# Route WebRTC (camera, mic, screen share) through PipeWire
--enable-features=WebRTCPipeWireCapturer
# Use the XDG portal for screen sharing and media access
--enable-features=UseOzonePlatform
EOF
        log_success "Chromium Wayland+PipeWire flags written to $flags_file"
    else
        log_info "Chromium flags file already exists: $flags_file"
    fi
}

if command_exists chromium; then
    _write_chromium_flags "$CHROMIUM_FLAGS_FILE"
elif command_exists chromium-browser; then
    _write_chromium_flags "$CHROMIUM_BROWSER_FLAGS_FILE"
fi

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
log_info "  - Audio: PipeWire + ALSA bridge + wireplumber"
log_info "  - Camera/Mic: v4l-utils + xdg-desktop-portal (wlr + gtk)"
log_info "  - Chromium: Wayland + PipeWire flags written to /etc/chromium/flags"
log_warn "Camera/mic in Chromium: allow access in site settings after first prompt"
log_warn "If mic/cam still fails: check 'wpctl status' and 'v4l2-ctl --list-devices'"
