#!/bin/bash
# 01-window-manager.sh - Install and configure i3 window manager with Catppuccin Mocha theme
# Creates a beautiful, keyboard-driven desktop environment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
ensure_pkgs \
    dunst \
    libnotify-bin \
    dbus

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
ensure_pkgs alsa-utils
if pkg_installed pipewire || apt-cache show pipewire-audio >/dev/null 2>&1; then
    log_info "PipeWire detected — installing PulseAudio compatibility layer..."
    ensure_pkgs \
        pipewire-audio \
        pipewire-pulse \
        pipewire-alsa \
        wireplumber \
        pulseaudio-utils 2>/dev/null || \
    ensure_pkgs \
        pipewire \
        pipewire-pulse \
        pipewire-alsa \
        pulseaudio-utils
    systemctl --global enable pipewire.service pipewire-pulse.service 2>/dev/null || true
    systemctl --global enable wireplumber.service 2>/dev/null || true
    log_success "PipeWire audio installed"
else
    log_info "PipeWire not available — installing PulseAudio..."
    ensure_pkgs pulseaudio pulseaudio-utils
    log_success "PulseAudio installed"
fi

# 9a. Camera / media device support
# v4l-utils:              Video4Linux2 userspace tools — required for webcam access
# xdg-desktop-portal:     Base portal daemon — Chromium requests mic/cam permissions through it
# xdg-desktop-portal-gtk: GTK backend — handles mic & camera permission dialogs
log_info "Installing camera and media device support..."
ensure_pkgs \
    v4l-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk || log_warn "Some media device packages unavailable"

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

# Try apt package first, then build from source
if command_exists i3lock-color; then
    log_success "i3lock-color already installed"
elif apt-get install -y -qq i3lock-color 2>/dev/null; then
    log_success "i3lock-color installed from apt"
else
    log_info "Building i3lock-color from source..."
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
log_info "Installing betterlockscreen..."
ensure_pkgs imagemagick x11-xserver-utils

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

# 16. Utility GUI Apps
log_info "Installing utility desktop applications..."
ensure_pkgs chromium || ensure_pkgs chromium-browser || log_warn "Chromium not available"
ensure_pkgs pavucontrol imv mpv

# 17. Display manager (lightdm login screen)
log_info "Installing display manager (lightdm)..."
ensure_pkgs \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings

# 18. Configure lightdm to use i3
log_info "Configuring lightdm session..."
if [[ -f /etc/lightdm/lightdm.conf ]]; then
    if ! grep -q "session=i3" /etc/lightdm/lightdm.conf 2>/dev/null; then
        backup_file /etc/lightdm/lightdm.conf
        if grep -q "^session=" /etc/lightdm/lightdm.conf; then
            sed -i 's/^session=.*/session=i3/' /etc/lightdm/lightdm.conf
        else
            echo "session=i3" >> /etc/lightdm/lightdm.conf
        fi
        log_success "lightdm configured to use i3 session"
    else
        log_info "lightdm already configured for i3"
    fi
fi

# 19. Enable lightdm
log_info "Enabling lightdm service..."
enable_service lightdm

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
    if curl -fsSL "https://git.io/papirus-icon-theme-install" -o /tmp/papirus-install.sh 2>/dev/null; then
        bash /tmp/papirus-install.sh 2>/dev/null || true
        rm -f /tmp/papirus-install.sh
    fi
}

# Install Catppuccin Rofi theme
log_info "Installing Catppuccin Mocha Rofi theme..."
mkdir -p "$HOME/.config/rofi"
if [[ ! -f "$HOME/.config/rofi/catppuccin-mocha.rasi" ]]; then
    ROFI_THEME_URL="https://raw.githubusercontent.com/catppuccin/rofi/main/basic/mocha.rasi"
    curl -fsSL "$ROFI_THEME_URL" -o "$HOME/.config/rofi/catppuccin-mocha.rasi" 2>/dev/null || log_warn "Rofi theme download failed"
fi

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
log_info "  - Audio: PipeWire (preferred)"
log_info "  - Lock Screen: betterlockscreen (blurred + Catppuccin ring)"
