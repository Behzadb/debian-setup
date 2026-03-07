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

# 5. GPU-accelerated terminal emulator (Kitty) + xterm as fallback
log_info "Installing terminal emulator (Kitty)..."
ensure_pkgs kitty xterm

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

# Install FiraCode Nerd Font (patched with 10,000+ icons for polybar, eza, starship)
log_info "Installing FiraCode Nerd Font (system-wide)..."
NERD_FONT_DIR="/usr/local/share/fonts/NerdFonts"
mkdir -p "$NERD_FONT_DIR"
if ! fc-list | grep -qi "FiraCode Nerd"; then
    NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    if curl -fsSL "$NERD_FONT_URL" -o /tmp/FiraCode-NF.zip 2>/dev/null; then
        unzip -qo /tmp/FiraCode-NF.zip -d "$NERD_FONT_DIR" '*.ttf' 2>/dev/null || true
        rm -f /tmp/FiraCode-NF.zip
        fc-cache -fv "$NERD_FONT_DIR" > /dev/null 2>&1
        log_success "FiraCode Nerd Font installed to $NERD_FONT_DIR"
    else
        log_warn "FiraCode Nerd Font download failed — install manually from github.com/ryanoasis/nerd-fonts"
    fi
else
    log_success "FiraCode Nerd Font already installed"
fi

# Also install JetBrains Mono Nerd Font (popular alternative)
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    JB_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    if curl -fsSL "$JB_FONT_URL" -o /tmp/JetBrainsMono-NF.zip 2>/dev/null; then
        unzip -qo /tmp/JetBrainsMono-NF.zip -d "$NERD_FONT_DIR" '*.ttf' 2>/dev/null || true
        rm -f /tmp/JetBrainsMono-NF.zip
        fc-cache -fv "$NERD_FONT_DIR" > /dev/null 2>&1
        log_success "JetBrains Mono Nerd Font installed"
    else
        log_warn "JetBrains Mono Nerd Font download failed"
    fi
else
    log_success "JetBrains Mono Nerd Font already installed"
fi

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
ensure_pkgs copyq

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
    BLS_VERSION=$(curl -s https://api.github.com/repos/betterlockscreen/betterlockscreen/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${BLS_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/betterlockscreen/betterlockscreen/releases/download/${BLS_VERSION}/betterlockscreen-${BLS_VERSION#v}-linux-x86_64" \
            -o /usr/local/bin/betterlockscreen 2>/dev/null && \
            chmod +x /usr/local/bin/betterlockscreen && \
            log_success "betterlockscreen ${BLS_VERSION} installed" || \
            log_warn "betterlockscreen download failed"
    else
        log_warn "Could not fetch betterlockscreen version, skipping"
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
log_info "  - Terminal: Kitty (GPU-accelerated)"
log_info "  - Status Bar: Polybar (Catppuccin themed)"
log_info "  - Theme: Catppuccin Mocha + Papirus-Dark icons"
log_info "  - Fonts: FiraCode + JetBrains Mono Nerd Fonts"
log_info "  - Audio: PipeWire (or PulseAudio fallback)"
log_info "  - Lock Screen: betterlockscreen (blurred + Catppuccin ring)"
