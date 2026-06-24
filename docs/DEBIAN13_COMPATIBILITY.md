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
| `linux-image-amd64` | ✅ | debian main |
| `linux-headers-amd64` | ✅ | debian main |
| `firmware-linux`, `firmware-linux-nonfree`, `firmware-misc-nonfree` | ✅ | debian non-free-firmware |
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
| `dunst`, `dbus`, `dbus-user-session` | ✅ | debian main (user D-Bus for PipeWire) |
| `copyq` | ✅ | debian main |
| `btop` | ✅ | debian main |
| `flameshot` | ✅ | debian main |
| `feh` | ✅ | debian main |
| `xserver-xorg` | ✅ | debian main |
| `fonts-dejavu`, `fonts-liberation`, `fonts-noto` | ✅ | debian main |
| `fonts-firacode`, `fonts-noto-color-emoji` | ✅ | debian main |
| `FiraCode Nerd Font` | ✅ | downloaded from github.com/ryanoasis/nerd-fonts to `/usr/local/share/fonts/` |
| `brightnessctl` | ✅ | debian main — replaces `xbacklight` (xbacklight broken on DRM/modern GPU) |
| `alsa-utils`, `pavucontrol` | ✅ | debian main (mixer GUI for mic/output selection) |
| `pipewire-audio`, `pipewire-pulse`, `wireplumber` | ✅ | debian main — **default on Debian 12+** |
| `libspa-0.2-bluetooth` | ✅ | debian main — **required for Bluetooth headset audio + mic** |
| `pulseaudio`, `pulseaudio-utils` | ⚠️ | fallback only — **conflicts with PipeWire if installed alongside** |
| `v4l-utils` | ✅ | debian main — webcam (V4L2) diagnostics + libv4l for Chromium |
| `bluez`, `blueman` | ✅ | debian main — Bluetooth stack + GTK manager applet |
| `imagemagick`, `x11-xserver-utils` | ✅ | debian main (required by betterlockscreen) |
| `lightdm`, `lightdm-gtk-greeter` | ✅ | debian main |
| `chromium` | ✅ | debian main |
| `thunar`, `gvfs` | ✅ | debian main |

### Security (03-security.sh)
All packages available:

| Package | Status | Source |
|---------|--------|--------|
| `ufw`, `fail2ban` | ✅ | debian main |
| `aide`, `aide-common` | ✅ | debian main |
| `auditd`, `audispd-plugins` | ✅ | debian main |
| `lynis`, `chkrootkit` | ✅ | debian main |
| `rkhunter` | ✅ | debian main |
| `gnupg` | ✅ | debian main (`gnupg2` is a transitional alias, dropped in trixie) |
| `unattended-upgrades` | ✅ | debian main |
| `fprintd`, `libpam-fprintd` | ✅ | debian main — installed only if a fingerprint reader is detected |

### Power Management (04-power-management.sh)
All packages available:

| Package | Status | Source |
|---------|--------|--------|
| `tlp` (≥1.5), `tlp-rdw` | ✅ | debian main — provides `PLATFORM_PROFILE_ON_AC/BAT` |
| `powertop`, `thermald` | ✅ | debian main |
| `acpi`, `acpid` | ✅ | debian main |
| `rfkill` | ✅ | debian main — backs the `radio-toggle` helper |
| `power-profiles-daemon` | ⛔ | **intentionally NOT installed** — conflicts with / masks TLP |
| `power-profile` (this repo) | ✅ | installed to `/usr/local/bin`; situational profile switcher |
| `radio-toggle` (this repo) | ✅ | installed to `/usr/local/bin`; WiFi/WWAN/BT/Ethernet toggle (rfkill + NetworkManager). TLP `tlp-rdw` also auto-disables idle radios by context. |

### Networking (05-networking.sh)
All core packages available:

| Package | Status | Source |
|---------|--------|--------|
| `wireguard`, `wireguard-tools` | ✅ | debian main |
| `mtr`, `tcpdump`, `nmap` | ✅ | debian main |
| `bind9-utils`, `bind9-dnsutils` | ✅ | debian main (`dig`/`nslookup`; replaces transitional `dnsutils`) |
| `systemd-resolved` | ✅ | debian main — separate package since Debian 12; installed before DNS config |
| `inetutils-telnet` | ✅ | debian main — replaces the retired `telnet` package |
| `modemmanager`, `libmbim-utils`, `libqmi-utils`, `usb-modeswitch`, `modem-manager-gui` | ✅ | debian main — installed only if a WWAN/cellular modem is detected |
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

### 2. **yq (YAML Processor)**
- **Installation**: from `apt` (`yq` package, in the dev-tools batch)
- **Status**: ✅ Available in Debian 12 & 13 `main`

### 3. **speedtest-cli**
- **Installation**: from `apt` (`speedtest-cli`); if unavailable the batch warns
  and continues (install via pip manually if you need it)
- **Status**: ✅ Available in Debian 12 & 13 `main`

### 4. **dnsutils → bind9-dnsutils** (important)
- **Old**: `dnsutils` (transitional package — **removed in trixie**)
- **New**: `bind9-dnsutils` (provides `dig`, `nslookup`, `nsupdate`; exists in 12 & 13)
- **Reason**: The transitional `dnsutils` is dropped in Debian 13. It was in a
  *bare* package batch in `00-base-system.sh`, so its removal would have aborted
  the base-system module under `set -e`.
- **Status**: ✅ Switched to `bind9-dnsutils` in `00` and `05`

### 5. **redis-tools → valkey-tools**
- **Old**: `redis-tools`
- **New**: `valkey-tools` (`valkey-cli`, redis-cli compatible)
- **Reason**: Redis was relicensed (non-DFSG); Debian 13 ships **Valkey** instead.
- **Status**: ✅ `02` tries `redis-tools` (Debian 12), falls back to `valkey-tools` (Debian 13)

### 6. **vagrant (dropped from Debian 13 main)**
- **Reason**: Vagrant's BSL relicense is not DFSG-free, so it's no longer in
  trixie `main`.
- **Status**: ✅ `02` installs it *best-effort* (`ensure_pkgs vagrant || log_warn`)
  so its absence never aborts the module; install from HashiCorp if needed.

### 7. **apt-transport-https (removed as unnecessary)**
- **Reason**: Modern `apt` (≥1.5, all of Debian 12/13) speaks HTTPS natively;
  `apt-transport-https` is an empty transitional package and a needless
  removal-risk in a bare batch.
- **Status**: ✅ Dropped from `00` and `02`

### 8. **telnet → inetutils-telnet, gnupg2 dropped**
- `telnet` is retired in trixie → `05` uses `inetutils-telnet`.
- `gnupg2` is a transitional alias of `gnupg` (gone in trixie) → removed from `03`.
- **Status**: ✅ Both handled

---

## 📦 External Repositories (Already Handled)

These require external repository configuration, which is handled in the scripts.
The Debian codename is resolved once (`lsb_release -cs`, falling back to
`/etc/os-release` `VERSION_CODENAME`); if a third-party repo doesn't yet publish
that codename, `02` removes the repo and falls back instead of leaving a broken
`sources.list.d` entry or aborting.

### Docker
```bash
# Repository: Docker Official (codename-aware; falls back to distro docker.io)
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian <codename> stable" | tee /etc/apt/sources.list.d/docker.list
```
**Status**: ✅ In `02-development-tools.sh` — falls back to `docker.io` if the repo refresh fails

### Terraform
```bash
# HashiCorp APT repo (codename-aware); falls back to the release binary from
# releases.hashicorp.com when the repo has no build for this codename (e.g. trixie)
```
**Status**: ✅ In `02-development-tools.sh` — apt repo first, release-binary fallback

### kubectl
```bash
# Download: Official Kubernetes release
curl -LOs "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
**Status**: ✅ Already in script 02-development-tools.sh

### kind
```bash
# Download: prebuilt binary from GitHub releases (latest tag resolved at runtime)
curl -fsSL "https://github.com/kubernetes-sigs/kind/releases/download/<tag>/kind-linux-amd64" -o /usr/local/bin/kind
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

### VSCodium (open-source VS Code)
```bash
# Repo uses a fixed 'vscodium main' suite (no Debian codename → works on any release)
curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor -o /usr/share/keyrings/vscodium-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main" | tee /etc/apt/sources.list.d/vscodium.list
```
**Status**: ✅ In `02-development-tools.sh` — installs the `codium` package (binary: `codium`)

### GitHub-release binaries — upstream status & asset names

These are fetched from GitHub releases (latest tag resolved at install time, except
where pinned). All are actively maintained as of 2026-06. The Linux/amd64 asset
naming differs per project — a wrong pattern means a silent non-install, so it is
recorded here:

| Tool | Repo | Active? | Linux amd64 asset pattern |
|------|------|---------|---------------------------|
| trippy | `fujiapple852/trippy` | ✅ | `trippy-<tag>-x86_64-unknown-linux-musl.tar.gz` (tag has **no** `v`) |
| doggo | `mr-karan/doggo` | ✅ | `doggo_<ver>_Linux_x86_64.tar.gz` (**capital** `Linux_x86_64`, not `linux_amd64`) |
| stern | `stern/stern` | ✅ | `stern_<ver>_linux_amd64.tar.gz` |
| k9s | `derailed/k9s` | ✅ | `k9s_Linux_amd64.tar.gz` |
| kind | `kubernetes-sigs/kind` | ✅ | `kind-linux-amd64` (raw binary) |
| kubestr | `kastenhq/kubestr` | ✅ (pinned v0.4.48) | `kubestr_<ver>_Linux_amd64.tar.gz` |
| lazygit | `jesseduffield/lazygit` | ✅ | `lazygit_<ver>_Linux_x86_64.tar.gz` |
| atuin | `atuinsh/atuin` | ✅ | `atuin-x86_64-unknown-linux-gnu.tar.gz` |
| eza | `eza-community/eza` | ✅ | `eza_x86_64-unknown-linux-gnu.tar.gz` (GitHub fallback; in apt on Debian 13) |
| ActivityWatch | `ActivityWatch/activitywatch` | ✅ (pinned v0.12.2) | `activitywatch-<tag>-linux-x86_64.zip` |
| i3lock-color | `Raymo111/i3lock-color` | ✅ | built from source |
| Nerd Fonts | `ryanoasis/nerd-fonts` | ✅ | `FiraCode.zip`, `JetBrainsMono.zip` |

**Deprecated but still functional**: the Catppuccin GTK theme (`catppuccin/gtk`,
pinned `v1.0.3`) is archived upstream, but the release asset still downloads. The
GTK theme is cosmetic — if the download ever fails, apps fall back to the default
GTK theme. (`papirus-icon-theme` comes from apt; the GitHub installer is only a
fallback and now uses the direct URL, not the deprecated `git.io` shortener.)

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

## 🧩 Package Coexistence & Conflicts (all handled)

Cases where two packages must not (or need not) be installed together, and how
the scripts keep the set consistent:

| Area | Conflict / dependency | How it's handled |
|------|-----------------------|------------------|
| **Audio** | `pulseaudio` (daemon) conflicts with `pipewire-pulse` | Mutually exclusive branches in `01`: PipeWire stack **or** PulseAudio, never both. `pulseaudio-utils` (just the `pactl` client) is safe with either. |
| **PipeWire session bus** | `systemctl --user` needs a user D-Bus | `dbus-user-session` is installed so PipeWire/WirePlumber socket-activate at login. |
| **Power** | `power-profiles-daemon` masks/conflicts with TLP | `04` never installs PPD and warns if it's already present (don't run both). |
| **Virtualization** | `libvirtd` service + `libvirt` group come from `libvirt-daemon-system` | `02` installs `libvirt-daemon-system` (not just `libvirt-daemon`) so `07` can add the user to `libvirt`/`kvm`. |
| **DNS** | DNS config targets `systemd-resolved` (separate package since Debian 12) | `05` installs `systemd-resolved` before writing/restarting its drop-in. |
| **Docker** | `docker-ce` (upstream repo) vs `docker.io` (Debian) | `02` only adds the Docker repo + `docker-ce` when no `docker` is already present. |
| **Firewall** | `ufw` and `fail2ban` both drive netfilter | Compatible on the Debian `iptables-nft` backend (default); no action needed. |
| **net-tools** | shell `ports` alias used `netstat` (net-tools, not installed) | Alias rewritten to `ss -tulpn` (from `iproute2`, in base). |
| **GnuPG** | `gnupg2` is transitional (→ `gnupg`) and dropped in Debian 13 | Removed; `gnupg` (in base) is used everywhere. |
| **pip (PEP 668)** | system `pip3 install` is blocked on Debian 12+ | apt is the primary source; the rare pip *fallbacks* pass `--break-system-packages`. |

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

