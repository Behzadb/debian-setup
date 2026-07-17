#!/bin/bash
# 01-window-manager.sh - Install and configure i3 window manager with Catppuccin Mocha theme
# Creates a beautiful, keyboard-driven desktop environment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

require_root

log_section "Window Manager Installation"

# 1. X11 server and input
log_info "Installing X11 server..."
ensure_pkgs \
    xserver-xorg \
    xserver-xorg-input-libinput \
    xinit \
    xclip \
    xsel

# 2. i3 window manager (meta-package pulls i3-wm, i3lock, i3status)
log_info "Installing i3 window manager..."
ensure_pkgs \
    i3 \
    i3status \
    i3lock

# 3. Application launcher (Rofi) and fallback (dmenu)
log_info "Installing launcher and switcher tools..."
ensure_pkgs \
    rofi \
    dmenu

# 4. Compositor for transparency and visual effects
log_info "Installing compositor (picom)..."
ensure_pkgs picom

# 5. GPU-accelerated terminal emulator (Kitty & Alacritty)
log_info "Installing terminal emulators..."
ensure_pkgs kitty alacritty xterm

# 6. Notification daemon (dunst — themed via dotfiles)
log_info "Installing notification system..."
# dbus-user-session provides the per-user D-Bus session that systemd --user units
# (PipeWire, WirePlumber) need — without it audio/mic socket activation can fail.
ensure_pkgs \
    dunst \
    libnotify-bin \
    dbus \
    dbus-user-session

# 7. Font rendering + Nerd Fonts
log_info "Installing fonts and rendering tools..."
ensure_pkgs \
    fonts-dejavu \
    fonts-liberation \
    fonts-noto \
    fonts-firacode \
    fonts-noto-color-emoji \
    fontconfig

# Install Nerd Fonts (patched with 10,000+ icons for polybar, eza, starship)
install_nerd_font "FiraCode" "FiraCode"
install_nerd_font "JetBrainsMono" "JetBrainsMono"

# 8. Brightness control
log_info "Installing brightness control tools..."
ensure_pkgs brightnessctl acpi

# 9. Audio (PipeWire preferred, PulseAudio fallback)
log_info "Installing audio system..."
# pavucontrol provides the GUI mixer used by the Polybar right-click action
# and the i3 floating rule for [class="Pavucontrol"].
ensure_pkgs alsa-utils pavucontrol
if pkg_installed pipewire || apt-cache show pipewire-audio >/dev/null 2>&1; then
    log_info "PipeWire detected — installing PulseAudio compatibility layer..."
    ensure_pkgs \
        pipewire-audio \
        pipewire-pulse \
        wireplumber \
        pulseaudio-utils 2>/dev/null || \
    ensure_pkgs \
        pipewire \
        pipewire-pulse \
        pulseaudio-utils
    systemctl --global enable pipewire.service pipewire-pulse.service 2>/dev/null || true
    systemctl --global enable wireplumber.service 2>/dev/null || true
    log_success "PipeWire audio installed"
else
    log_info "PipeWire not available — installing PulseAudio..."
    ensure_pkgs pulseaudio pulseaudio-utils
    log_success "PulseAudio installed"
fi

# 9b. Webcam / camera support (V4L2)
# The uvcvideo kernel driver handles most USB/laptop webcams out of the box;
# v4l-utils provides diagnostics (v4l2-ctl) and the libv4l userspace layer that
# Chromium/WebRTC use. Device firmware comes from firmware-misc-nonfree (base).
log_info "Installing webcam (V4L2) support..."
ensure_pkgs v4l-utils

# 9c. Bluetooth (referenced by TLP power profile; needed for BT headsets/mice)
# libspa-0.2-bluetooth is REQUIRED for PipeWire Bluetooth audio — without it a
# Bluetooth headset connects but has no sound and no working microphone.
# blueman is the GTK applet/manager (shows in the Polybar tray).
log_info "Installing Bluetooth support..."
ensure_pkgs bluez libspa-0.2-bluetooth blueman
enable_service bluetooth
start_service bluetooth

# 10. Wallpaper setter
log_info "Installing wallpaper tools..."
ensure_pkgs feh

# 11. Screenshot tools (GUI region select + annotation)
log_info "Installing screenshot utilities..."
ensure_pkgs flameshot

# 12. Polybar status bar (Catppuccin themed via dotfiles)
log_info "Installing Polybar status bar..."
ensure_pkgs polybar

# 12a. Clipboard manager
log_info "Installing clipboard manager (copyq)..."
ensure_pkgs copyq pinentry-qt gnupg

# 12b. btop system monitor (replaces htop)
log_info "Installing btop system monitor..."
ensure_pkgs btop

# 13. i3lock-color (required by betterlockscreen for Catppuccin color ring)
log_info "Installing i3lock-color build dependencies..."
ensure_pkgs \
    libxcb1-dev libxcb-util0-dev libpam0g-dev libcairo2-dev \
    libxcb-xinerama0-dev libev-dev libx11-dev libx11-xcb-dev \
    libxkbcommon-dev libxkbfile-dev libxcb-composite0-dev \
    libxcb-image0-dev libxcb-xkb-dev libxcb-randr0-dev \
    autoconf automake libtool pkg-config || true

# Try apt package first, then build from source.
# NOTE: the fork installs a binary named `i3lock` (it replaces stock i3lock), so
# detect it by version string rather than a non-existent `i3lock-color` command —
# otherwise every re-run rebuilds from source.
if command_exists i3lock && i3lock --version 2>&1 | grep -qi 'i3lock-color'; then
    log_success "i3lock-color already installed"
elif apt-get install -y -qq i3lock-color 2>/dev/null; then
    log_success "i3lock-color installed from apt"
else
    log_info "Building i3lock-color from source..."
    rm -rf /tmp/i3lock-color   # clear any leftover from an interrupted run
    if git clone --depth 1 https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color 2>/dev/null; then
        (
            cd /tmp/i3lock-color
            autoreconf --force --install > /dev/null 2>&1 && \
            ./configure > /dev/null 2>&1 && \
            make -j"$(nproc)" > /dev/null 2>&1 && \
            make install > /dev/null 2>&1 && \
            log_success "i3lock-color built and installed"
        ) || log_warn "i3lock-color build failed — betterlockscreen will use plain i3lock"
        rm -rf /tmp/i3lock-color
    else
        log_warn "i3lock-color clone failed"
    fi
fi

# 14. Betterlockscreen (fancy blurred lock screen)
# xss-lock ties the locker to logind: it locks the screen *before* the system
# suspends (lid close / `systemctl suspend`) and on X screensaver idle.
log_info "Installing betterlockscreen..."
ensure_pkgs imagemagick x11-xserver-utils xss-lock

if ! command_exists betterlockscreen; then
    # Use the official install script for system-wide installation
    if curl -fsSL "https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh" -o /tmp/bls-install.sh 2>/dev/null; then
        bash /tmp/bls-install.sh system >/dev/null 2>&1 && \
        log_success "betterlockscreen installed via official script" || \
        log_warn "betterlockscreen installation failed"
        rm -f /tmp/bls-install.sh
    else
        log_warn "Could not download betterlockscreen installation script"
    fi
else
    log_success "betterlockscreen already installed"
fi

# 15. File manager
log_info "Installing file manager..."
ensure_pkgs thunar gvfs

# 16. Web browser
log_info "Installing web browser..."
ensure_pkgs chromium || ensure_pkgs chromium-browser || log_warn "Chromium not available"

# 17. Display manager (lightdm login screen)
log_info "Installing display manager (lightdm)..."
ensure_pkgs \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings

# 18. Configure lightdm to use i3 as the default session
# The correct key is "user-session" under [Seat:*] — there is no "session" key.
# Use a drop-in under lightdm.conf.d so we never clobber the main config.
log_info "Configuring lightdm to default to the i3 session..."
LIGHTDM_DROPIN="/etc/lightdm/lightdm.conf.d/50-debian-setup.conf"
if [[ ! -f "$LIGHTDM_DROPIN" ]]; then
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat > "$LIGHTDM_DROPIN" << 'EOF'
# Default the login session to i3 — generated by debian-setup
# Value must match an xsession in /usr/share/xsessions/ (i3.desktop ships with i3-wm)
[Seat:*]
user-session=i3
EOF
    log_success "lightdm default session set to i3 ($LIGHTDM_DROPIN)"
else
    log_info "lightdm i3 session drop-in already exists"
fi

# 19. Enable lightdm
log_info "Enabling lightdm service..."
enable_service lightdm

# 19b. Display hotplug — auto-apply the monitor layout + Polybar when an external
# display is connected/disconnected (without it, you must press Super+Shift+N).
# A udev DRM "change" event triggers a oneshot service that re-runs the user's
# setup-monitors.sh in their X session. ENV{HOTPLUG}=="1" limits it to real
# connector changes (not every DRM event).
log_info "Installing display hotplug auto-configuration..."
if [[ -f "$REPO_DIR/config/i3/monitor-hotplug.sh" ]]; then
    install -m 0755 -o root -g root "$REPO_DIR/config/i3/monitor-hotplug.sh" /usr/local/bin/monitor-hotplug
    cat > /etc/systemd/system/monitor-hotplug.service << 'EOF'
[Unit]
Description=Reconfigure monitors + Polybar on display hotplug
[Service]
Type=oneshot
ExecStart=/usr/local/bin/monitor-hotplug
# Leave the relaunched Polybar running after the script exits — the default
# (control-group) would kill it together with the oneshot.
KillMode=process
EOF
    cat > /etc/udev/rules.d/95-monitor-hotplug.rules << 'EOF'
# Re-run the i3 monitor layout when a display is connected/disconnected.
ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", RUN+="/usr/bin/systemctl --no-block restart monitor-hotplug.service"
EOF
    systemctl daemon-reload 2>/dev/null || true
    udevadm control --reload-rules 2>/dev/null || true
    log_success "Display hotplug auto-configuration installed"
else
    log_warn "monitor-hotplug.sh not found in repo — skipping display hotplug"
fi

# ============================================================================
# 20. Catppuccin GTK Theme + Papirus Icons (consistent desktop theming)
# ============================================================================
log_section "Desktop Theming — Catppuccin Mocha"

log_info "Installing theme dependencies..."
ensure_pkgs lxappearance gtk2-engines-murrine sassc || true

# Install Catppuccin GTK theme
CATPPUCCIN_GTK_DIR="/usr/share/themes/catppuccin-mocha-blue-standard+default"
if [[ ! -d "$CATPPUCCIN_GTK_DIR" ]]; then
    log_info "Installing Catppuccin Mocha GTK theme..."
    CATPPUCCIN_GTK_URL="https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-blue-standard+default.zip"
    if curl -fsSL "$CATPPUCCIN_GTK_URL" -o /tmp/catppuccin-gtk.zip 2>/dev/null; then
        unzip -qo /tmp/catppuccin-gtk.zip -d /usr/share/themes/ 2>/dev/null || true
        rm -f /tmp/catppuccin-gtk.zip
        log_success "Catppuccin Mocha GTK theme installed"
    else
        log_warn "Catppuccin GTK theme download failed — install manually"
    fi
else
    log_success "Catppuccin GTK theme already installed"
fi

# Install Papirus icon theme (modern, crisp icons)
log_info "Installing Papirus icon theme..."
ensure_pkgs papirus-icon-theme || {
    log_info "Papirus not in apt — downloading..."
    # Direct URL (the old git.io shortener is deprecated and may disappear)
    PAPIRUS_INSTALL_URL="https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh"
    if curl -fsSL "$PAPIRUS_INSTALL_URL" -o /tmp/papirus-install.sh 2>/dev/null; then
        bash /tmp/papirus-install.sh 2>/dev/null || true
        rm -f /tmp/papirus-install.sh
    fi
}

# Rofi theme: the Catppuccin Mocha theme and config are shipped in this repo
# (config/rofi/) and symlinked into ~/.config/rofi by the dotfiles module
# (06-dotfiles.sh). No download needed here.

# Set dark GTK theme system-wide
GTK3_SETTINGS="/etc/gtk-3.0/settings.ini"
if [[ ! -f "$GTK3_SETTINGS" ]] || ! grep -q "catppuccin" "$GTK3_SETTINGS" 2>/dev/null; then
    mkdir -p /etc/gtk-3.0
    cat > "$GTK3_SETTINGS" << 'EOF'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=FiraCode Nerd Font 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=true
gtk-decoration-layout=:close
EOF
    log_success "GTK3 dark theme configured system-wide"
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_section "Window Manager Setup Complete"
log_info "Desktop environment ready:"
log_info "  - Display Manager: lightdm"
log_info "  - Window Manager: i3 (keyboard-driven tiling)"
log_info "  - Terminals: Kitty (GPU), Alacritty (GPU)"
log_info "  - Status Bar: Polybar (Catppuccin themed)"
log_info "  - Theme: Catppuccin Mocha + Papirus-Dark icons"
log_info "  - Fonts: FiraCode + JetBrains Mono Nerd Fonts"
log_info "  - Launcher: Rofi (Catppuccin themed)"
log_info "  - Audio: PipeWire (preferred) + pavucontrol mixer"
log_info "  - Webcam: V4L2 (uvcvideo) + v4l-utils"
log_info "  - Bluetooth: bluez + blueman (PipeWire BT audio/mic)"
log_info "  - Lock Screen: betterlockscreen (blurred + Catppuccin ring)"
