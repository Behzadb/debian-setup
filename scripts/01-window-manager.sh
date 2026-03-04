#!/bin/bash
# 01-window-manager.sh - Install and configure i3 window manager

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root"
    exit 1
fi

log_info "Starting window manager installation..."

# 1. Install X11 and minimal desktop environment
log_info "Installing X11 server..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    xserver-xorg \
    xserver-xorg-input-libinput \
    xinit \
    xclip \
    xsel

# 2. Install i3 window manager
log_info "Installing i3 window manager..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    i3 \
    i3-wm \
    i3status \
    i3lock

# 3. Install application launcher and related tools
log_info "Installing launcher and switcher tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    rofi \
    dmenu

# 4. Install compositor for transparency and visual effects
log_info "Installing compositor..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    picom

# 5. Install GPU-accelerated terminal emulator
log_info "Installing terminal emulator (Kitty)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    kitty

# 6. Install notification daemon
log_info "Installing notification system..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    dunst \
    libnotify-bin \
    dbus

# 7. Install font rendering improvements + Nerd Fonts
log_info "Installing fonts and rendering tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    fonts-dejavu \
    fonts-liberation \
    fonts-noto \
    fonts-firacode \
    fonts-noto-color-emoji \
    fontconfig

# Install FiraCode Nerd Font (patched with 10,000+ icons for polybar, eza, starship)
log_info "Installing FiraCode Nerd Font..."
NERD_FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
mkdir -p "$NERD_FONT_DIR"
if ! fc-list | grep -qi "FiraCode Nerd"; then
    NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    if curl -fsSL "$NERD_FONT_URL" -o /tmp/FiraCode-NF.zip 2>/dev/null; then
        unzip -qo /tmp/FiraCode-NF.zip -d "$NERD_FONT_DIR" '*.ttf' 2>/dev/null || true
        rm -f /tmp/FiraCode-NF.zip
        fc-cache -fv "$NERD_FONT_DIR" > /dev/null 2>&1
        log_info "FiraCode Nerd Font installed"
    else
        log_warn "FiraCode Nerd Font download failed - install manually from github.com/ryanoasis/nerd-fonts"
    fi
else
    log_warn "FiraCode Nerd Font already installed"
fi

# 8. Install screen brightness control
log_info "Installing brightness control tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    xbacklight \
    acpi

# 9. Install volume control
log_info "Installing audio control tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    alsa-utils \
    pulseaudio \
    pulseaudio-utils

# 10. Install wallpaper setter
log_info "Installing wallpaper tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    feh

# 11. Install screenshot tools
log_info "Installing screenshot utilities (flameshot - GUI region select + annotation)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    flameshot

# 12. Install Polybar (beautiful, icon-capable status bar replacing i3status)
log_info "Installing Polybar status bar..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    polybar

# 12a. Install clipboard manager
log_info "Installing clipboard manager (copyq)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    copyq

# 12b. Install btop (modern system monitor replacing htop)
log_info "Installing btop system monitor..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    btop

# 13. Install betterlockscreen (fancy blurred lock screen replacing i3lock)
log_info "Installing betterlockscreen (blurred wallpaper lock screen)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    imagemagick \
    x11-xserver-utils

if ! command -v betterlockscreen &> /dev/null; then
    BLS_VERSION=$(curl -s https://api.github.com/repos/betterlockscreen/betterlockscreen/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [ -n "$BLS_VERSION" ]; then
        curl -fsSL "https://github.com/betterlockscreen/betterlockscreen/releases/download/${BLS_VERSION}/betterlockscreen-${BLS_VERSION#v}-linux-x86_64" \
            -o /usr/local/bin/betterlockscreen 2>/dev/null && \
            chmod +x /usr/local/bin/betterlockscreen && \
            log_info "betterlockscreen ${BLS_VERSION} installed" || \
            log_warn "betterlockscreen download failed - install manually from github.com/betterlockscreen/betterlockscreen"
    else
        log_warn "Could not fetch betterlockscreen version, skipping"
    fi
else
    log_warn "betterlockscreen already installed"
fi

# 14. Install file manager
log_info "Installing file manager..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    thunar \
    gvfs

# 13. Install web browser
log_info "Installing web browser..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    chromium

# 14. Install lightweight display manager (login screen)
log_info "Installing display manager (lightdm)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings

# 14. Configure lightdm to use i3
log_info "Configuring lightdm session..."
if grep -q "session=i3" /etc/lightdm/lightdm.conf 2>/dev/null; then
    log_warn "lightdm already configured for i3"
else
    # Set i3 as default session
    if [ -f /etc/lightdm/lightdm.conf ]; then
        # Backup original
        cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
        
        # Update or add session line
        if grep -q "^session=" /etc/lightdm/lightdm.conf; then
            sed -i 's/^session=.*/session=i3/' /etc/lightdm/lightdm.conf
        else
            echo "session=i3" >> /etc/lightdm/lightdm.conf
        fi
        log_success "lightdm configured to use i3 session"
    fi
fi

# 15. Enable lightdm service to start at boot
log_info "Enabling lightdm service..."
systemctl enable lightdm 2>/dev/null || log_warn "Could not enable lightdm service"
log_success "lightdm service enabled (will start on next boot)"

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_info "Window manager installation completed!"
log_info "Desktop environment is ready:"
log_info "  - Display Manager: lightdm (will start at next boot)"
log_info "  - Window Manager: i3 (keyboard-driven tiling)"
log_info "  - Terminal: Kitty (GPU-accelerated, ligatures, image protocol)"
log_info "  - Status Bar: Polybar (click actions, icon support, Catppuccin themed)"
log_info "  - Screenshot: flameshot (GUI region select, annotation, clipboard)"
log_info "  - Clipboard: copyq (persistent history across sessions)"
log_info "  - System Monitor: btop (graphs, mouse support, all-in-one)"
log_info "  - Fonts: FiraCode Nerd Font (icons for polybar/eza/starship)"
log_info "  - Session: Configured to use i3"
log_info ""
log_info "Next steps:"
log_info "  1. After reboot, log in via lightdm (it will be the login screen)"
log_info "  2. Once logged in, read i3 keybindings: ~/.config/i3/config"
log_info "  3. Polybar auto-starts - click workspace buttons, battery, volume"
log_info "  4. Press Super+G to open lazygit, Super+Shift+V for clipboard history"
log_info "  5. Press Print for flameshot screenshot with annotation"
log_warn "NOTE: lightdm will start automatically on next boot"
log_warn "NOTE: To start X11 manually before reboot, run: startx"
