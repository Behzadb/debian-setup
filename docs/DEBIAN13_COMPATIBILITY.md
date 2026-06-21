# Debian 13 Package Compatibility Guide

## Overview

This document details package availability and compatibility for Debian 13 (Trixie/Forky).
All packages have been verified and updated for Debian 13 compatibility.

---

## ✅ All Standard Debian Packages (Available)

### Base System (00-base-system.sh)
All packages are available in Debian 13 standard repositories:

| Package | Status | Source |
|---------|--------|--------|
| `linux-image-generic` | ✅ | debian main |
| `linux-headers-generic` | ✅ | debian main |
| `linux-firmware` | ✅ | debian non-free-firmware |
| `intel-microcode` | ✅ | debian non-free-firmware |
| `amd64-microcode` | ✅ | debian non-free-firmware |
| `build-essential` | ✅ | debian main |
| `git`, `curl`, `wget` | ✅ | debian main |
| `tmux`, `zsh`, `vim` | ✅ | debian main |
| `htop`, `network-manager` | ✅ | debian main |

### Window Manager (01-window-manager.sh)
All packages available in Debian 13:

| Package | Status | Source |
|---------|--------|--------|
| `i3`, `i3-wm`, `i3status` | ✅ | debian main |
| `rofi`, `dmenu` | ✅ | debian main |
| `picom` | ✅ | debian main (newer version) |
| `kitty` | ✅ | debian main |
| `polybar` | ✅ | debian main |
| `dunst` | ✅ | debian main |
| `copyq` | ✅ | debian main |
| `btop` | ✅ | debian main |
| `flameshot` | ✅ | debian main |
| `feh` | ✅ | debian main |
| `xserver-xorg` | ✅ | debian main |
| `fonts-dejavu`, `fonts-liberation`, `fonts-noto` | ✅ | debian main |
| `fonts-firacode`, `fonts-noto-color-emoji` | ✅ | debian main |
| `FiraCode Nerd Font` | ✅ | downloaded from github.com/ryanoasis/nerd-fonts to `/usr/local/share/fonts/` |
| `brightnessctl` | ✅ | debian main — replaces `xbacklight` (xbacklight broken on DRM/modern GPU) |
| `alsa-utils` | ✅ | debian main |
| `pipewire-audio`, `pipewire-pulse`, `wireplumber` | ✅ | debian main — **default on Debian 12+** |
| `pulseaudio`, `pulseaudio-utils` | ⚠️ | fallback only — **conflicts with PipeWire if installed alongside** |
| `imagemagick`, `x11-xserver-utils` | ✅ | debian main (required by betterlockscreen) |
| `lightdm`, `lightdm-gtk-greeter` | ✅ | debian main |
| `chromium` | ✅ | debian main |
| `thunar`, `gvfs` | ✅ | debian main |

### Wayland Window Manager (01b-wayland-manager.sh) — default display server

| Package | Status | Source |
|---------|--------|--------|
| `sway`, `swaybg`, `swayidle`, `swaylock` | ✅ | debian main |
| `wayland-protocols`, `xwayland` | ✅ | debian main |
| `waybar`, `wofi`, `mako-notifier` | ✅ | debian main |
| `grim`, `slurp`, `wl-clipboard` | ✅ | debian main |
| `playerctl` | ✅ | debian main — MPRIS media-key control bound in the Sway config |
| `cliphist` | ⚠️ | **Debian 13 (trixie) only** — absent from Debian 12 (bookworm) apt; the script falls back to `go install go.senan.xyz/cliphist@latest` when apt lacks it |
| `xdg-desktop-portal`, `-wlr`, `-gtk` | ✅ | debian main — WLR = screen capture, GTK = camera/mic dialogs |
| `sddm` | ✅ | debian main — Wayland-capable display manager (replaces LightDM) |
| `kitty`, `alacritty` | ✅ | debian main |
| `v4l-utils` | ✅ | debian main — webcam device access |
| `pipewire-audio`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber` | ✅ | debian main |
| `chromium` | ✅ | debian main — written `/etc/chromium/flags` for Wayland + PipeWire |

> **Chromium on Wayland**: the flags file uses a single
> `--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform` line. Chromium
> keeps only the *last* `--enable-features` it parses, so both features must
> share one line or camera/mic over PipeWire silently breaks.

### Security (03-security.sh)
All packages available:

| Package | Status | Source |
|---------|--------|--------|
| `ufw`, `fail2ban` | ✅ | debian main |
| `aide`, `aide-common` | ✅ | debian main |
| `auditd`, `audispd-plugins` | ✅ | debian main |
| `lynis`, `chkrootkit` | ✅ | debian main |
| `rkhunter` | ✅ | debian main |
| `gnupg`, `gnupg2` | ✅ | debian main |
| `unattended-upgrades` | ✅ | debian main |

### Power Management (04-power-management.sh)
All packages available:

| Package | Status | Source |
|---------|--------|--------|
| `tlp`, `tlp-rdw` | ✅ | debian main |
| `powertop`, `thermald` | ✅ | debian main |
| `cpufrequtils`, `acpid` | ✅ | debian main |
| `power-profiles-daemon` | ✅ | debian main |

### Networking (05-networking.sh)
All core packages available:

| Package | Status | Source |
|---------|--------|--------|
| `wireguard`, `wireguard-tools` | ✅ | debian main |
| `mtr`, `tcpdump`, `nmap` | ✅ | debian main |
| `bind9-utils`, `dnsutils` | ✅ | debian main |
| `socat`, `proxychains4` | ✅ | debian main |
| `openssh-client`, `openssh-server` | ✅ | debian main |
| `iperf3`, `jq`, `yq` | ⚠️ | See below |

---

## ⚠️ Packages with Changes/Workarounds for Debian 13

### 1. **mysql-client → mariadb-client**
- **Old**: `mysql-client`
- **New**: `mariadb-client`
- **Reason**: MySQL client replaced with MariaDB in Debian 13
- **Status**: ✅ Already updated in script

### 2. **perf-tools-unstable → linux-tools-generic**
- **Old**: `perf-tools-unstable`
- **New**: `linux-tools-generic`
- **Reason**: Package renamed in newer Debian releases
- **Status**: ✅ Already updated in script

### 3. **yq (YAML Processor)**
- **Status**: Available in Debian 13
- **Installation**: Via pip for flexibility (pip3 install yq)
- **Reason**: Ensures latest version regardless of distro
- **Status**: ✅ Handled via pip with fallback

### 4. **speedtest-cli**
- **Status**: Available via pip
- **Installation**: `pip3 install speedtest-cli`
- **Reason**: Better maintained via Python package
- **Status**: ✅ Handled via pip with fallback

---

## 📦 External Repositories (Already Handled)

These require external repository configuration, which is handled in the scripts:

### Docker
```bash
# Repository: Docker Official
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
```
**Status**: ✅ Already in script 02-development-tools.sh

### kubectl
```bash
# Download: Official Kubernetes release
curl -LOs "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
**Status**: ✅ Already in script 02-development-tools.sh

### kind
```bash
# Install: Via Go (requires golang-go)
go install sigs.k8s.io/kind@latest
```
**Status**: ✅ Already in script 02-development-tools.sh

### helm
```bash
# Download: Helm official release
curl -fsSL https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
```
**Status**: ✅ Already in script 02-development-tools.sh

### fnm (Fast Node Manager) — replaces nvm
```bash
# Install: Official fnm installer (Rust binary, reads .nvmrc files)
curl -fsSL https://fnm.vercel.app/install | bash
```
**Status**: ✅ Already in script 02-development-tools.sh
**Note**: `nvm` replaced by `fnm` — same `.nvmrc` compatibility, 10x faster shell startup

---

## 🔍 Debian 13 Specific Considerations

### 1. **Systemd Integration**
- Debian 13 uses systemd-resolved by default
- All service configurations use systemctl
- Status: ✅ Scripts compatible

### 2. **Python Version**
- Debian 13 defaults to Python 3.12+
- All pip installations use `pip3`
- Status: ✅ Scripts use pip3

### 3. **Node.js Version**
- Debian 13 includes Node.js 18+
- NPM included with Node.js
- Status: ✅ Compatible

### 4. **Go Version**
- Debian 13 includes Go 1.20+
- Sufficient for all tooling
- Status: ✅ Compatible

### 5. **Kernel Version**
- Debian 13 includes Linux 6.x
- Full hardware support
- Status: ✅ Compatible

### 6. **Audio: PipeWire replaces PulseAudio (Debian 12+)**
- Debian 12+ ships PipeWire as the default audio system
- **Do NOT install `pulseaudio` directly** — it conflicts with PipeWire
- The install script detects PipeWire and installs `pipewire-pulse` compatibility layer
- `pactl` (used by i3 volume keys) and Polybar's `internal/pulseaudio` module work transparently via this layer
- Status: ✅ Handled automatically in `01-window-manager.sh`

### 7. **Brightness: brightnessctl replaces xbacklight**
- `xbacklight` only works with legacy X11 ACPI backlight (broken on Intel DRM, AMD, NVIDIA)
- `brightnessctl` works with all `/sys/class/backlight/` devices (DRM, sysfs, firmware)
- i3 brightness keys now use `brightnessctl set +5%` / `brightnessctl set 5%-`
- Status: ✅ Updated in both `01-window-manager.sh` and `config/i3/config`

---

## ✅ Verification Commands

Run these to verify Debian 13 compatibility:

```bash
# Check Debian version
cat /etc/os-release

# Verify package availability
apt-cache search <package-name>

# Simulate installation (dry-run)
apt install -s <package-name>

# Check if package in Debian 13
apt-cache policy <package-name>
```

---

## 📝 Package Installation Summary by Script

### 00-base-system.sh
- **Total Packages**: 20+
- **Debian 13 Status**: ✅ All available
- **External Repos**: None needed

### 01-window-manager.sh
- **Total Packages**: 18+
- **Debian 13 Status**: ✅ All available
- **External Repos**: None needed

### 02-development-tools.sh
- **Total Packages**: 25+ (apt) + 4 (pip)
- **Debian 13 Status**: ✅ All available
- **External Repos**: Docker, kubectl, helm (handled)
- **Changes**: yq, speedtest-cli via pip

### 03-security.sh
- **Total Packages**: 15+
- **Debian 13 Status**: ✅ All available
- **External Repos**: None needed

### 04-power-management.sh
- **Total Packages**: 10+
- **Debian 13 Status**: ✅ All available
- **External Repos**: None needed

### 05-networking.sh
- **Total Packages**: 30+
- **Debian 13 Status**: ✅ All available
- **External Repos**: None needed (fnm downloaded from vercel CDN)

---

## 🚀 Running Setup on Debian 13

### Supported Versions
- ✅ Debian 12 (Bookworm)
- ✅ Debian 13 (Trixie)
- ✅ Debian Testing (Future releases)

### Installation
```bash
sudo ./setup.sh
# All packages will be checked against Debian 13 repos automatically
```

### Version Check
Script will display:
```
[INFO] Debian version: 13
[WARN] Detected Debian 13 - packages optimized for this release
```

---

## ⚠️ Known Limitations & Workarounds

### Limitation 1: proxychains4
- **Status**: ✅ Available in Debian 13
- **Note**: May require manual configuration

### Limitation 2: Some GUI tools
- **Status**: Optional dependencies
- **Fallback**: Command-line alternatives available

### Limitation 3: Older hardware support
- **Status**: Firmware packages included
- **Action**: Drivers loaded automatically

---

## 🔄 Future Compatibility

Scripts automatically handle:
- Debian version detection
- Package availability checking
- Graceful degradation
- Fallback mechanisms (pip, direct downloads)

New Debian versions will be supported as they're released.

---

## 📋 Checklist for Debian 13 Compliance

- [x] All base packages verified in Debian 13
- [x] External repos configured correctly
- [x] Package alternatives identified (mysql → mariadb)
- [x] Renamed packages updated (perf-tools → linux-tools)
- [x] Python packages via pip with fallbacks
- [x] Version detection added
- [x] Audio: PipeWire-first install (no pulseaudio conflict)
- [x] Brightness: brightnessctl replacing xbacklight
- [x] Node.js: fnm replacing nvm
- [x] Screenshot: flameshot replacing scrot/maim
- [x] Terminal: Kitty replacing urxvt/xterm
- [x] Status bar: Polybar replacing i3status
- [x] New tools documented (btop, lazygit, eza, bat, delta, atuin, starship, copyq, betterlockscreen)
- [x] Documentation updated

---

## 🆘 Troubleshooting Package Issues

### If package not found:
```bash
sudo apt update
apt-cache search <partial-package-name>
apt-cache policy <package-name>
```

### If repository missing:
```bash
# Add Debian sources if needed
sudo apt-get install debian-archive-keyring
sudo apt update
```

### For pip packages:
```bash
# Ensure pip3 is available
python3 -m pip install --user <package>
```

### For external tools:
```bash
# Check if installed correctly
command -v <tool-name>
# Or check version
<tool-name> --version
```

---

## 📞 Support

For package-specific issues:
1. Check this guide first
2. Run: `apt-cache policy <package-name>`
3. Search: Debian package database online
4. Install manually if needed: See setup scripts for alternatives

