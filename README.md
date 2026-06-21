# Debian Productive Development Environment Setup

An opinionated, idempotent Debian netinstall → productive development workstation in one command.

![Status](https://img.shields.io/badge/status-production-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Debian](https://img.shields.io/badge/distro-Debian%2012+-orange)

## Purpose

Transform a minimal Debian netinstall into a **lightweight, secure, productive development environment** optimized for:
- **Software Development**: Go, Python, Node.js, TypeScript
- **DevOps & Cloud**: Docker, Kubernetes, Terraform, Ansible
- **System Efficiency**: Power management, thermal optimization
- **Security**: Firewall, intrusion detection, SSH hardening
- **Productivity**: Tiling window manager, terminal multiplexing, fuzzy finding

---

## Features

| Feature | What's Included |
|---------|-----------------|
| **Display Server** | **Wayland** (Sway + Waybar + Wofi) or **X11** (i3 + Polybar + Rofi) |
| **Terminal** | Kitty — GPU-accelerated, FiraCode ligatures, image protocol |
| **Shell** | Starship prompt + atuin history + Zsh/Bash with 50+ aliases |
| **CLI Tools** | eza, bat, delta, btop, lazygit replacing dated alternatives |
| **Containerization** | Docker + Docker Compose |
| **Kubernetes** | kubectl, helm, kind, k9s, kubectx, kubens, stern, kustomize |
| **Virtualization** | KVM/QEMU + Vagrant |
| **Languages** | Python 3 + uv, Go, Node.js + fnm |
| **IaC** | Terraform + Ansible |
| **DevSecOps** | Trivy (scan), Dive (image explorer), SOPS (secrets) |
| **Security** | UFW, fail2ban, AIDE, SSH hardening, auditd |
| **Power** | TLP, thermald, CPU frequency scaling |
| **Networking** | WireGuard, mtr, nmap, tcpdump, iperf3, trippy, doggo |
| **Editors** | Neovim (LazyVim) + VSCodium + lazygit |
| **Theme** | Catppuccin Mocha across all components |
| **Productivity** | ActivityWatch, tmux, copyq/wl-clipboard |

---

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/yourusername/debian-setup.git
cd debian-setup

# 2. (Optional) Pin specific tool versions
cp versions.env versions.env.local   # edit to pin, e.g. KUBECTL_VERSION=v1.30.3
source versions.env.local

# 3. Run setup (root required)
sudo ./setup.sh
# Choose: F = Full, C = Custom, M = Minimal, D = Dev+Dotfiles
# Choose display server: 1 = X11/i3, 2 = Wayland/Sway (default)

# 4. Post-install
sudo usermod -aG docker $USER

# 5. Verify everything is working
sudo bash scripts/09-verify.sh

# 6. (Optional) Update development binaries
bash scripts/update-binaries.sh
```

**Installation time**: ~15–25 minutes (full install)

---

## What Gets Installed

### Base System (always)
- Linux firmware + CPU microcode (Intel/AMD auto-detected)
- Build tools: gcc, make, git, curl
- Core utilities and shell configuration

### Display Server (choose one)
- **Wayland (default)**: Sway WM, Waybar, Wofi, grim, slurp, mako, wl-clipboard + cliphist (clipboard history), playerctl (media keys), SDDM
- **X11 (legacy)**: i3 WM, Polybar, Rofi, Dunst, picom, betterlockscreen, LightDM
- Shared: Kitty terminal, FiraCode Nerd Font, Catppuccin Mocha theme, btop

**Audio / Camera / Microphone** (both display servers):
- PipeWire + `pipewire-pulse` + `pipewire-alsa` + wireplumber — full audio stack with ALSA bridge
- `v4l-utils` — Video4Linux2 userspace for webcam device access
- `xdg-desktop-portal` + `xdg-desktop-portal-gtk` — mic & camera permission dialogs for Chromium/Firefox
- `xdg-desktop-portal-wlr` (Wayland only) — screen capture (OBS, browser screenshare)
- Chromium flags on Wayland: `--ozone-platform=wayland` + `--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform` written to `/etc/chromium/flags` (both features on one line — Chromium honors only the last `--enable-features`)

### Development Tools
- Languages: Go, Python 3 + **uv**, Node.js + **fnm**
- Containers: Docker + Docker Compose
- Kubernetes: kubectl, helm, kind, k9s, kubectx, kubens, stern, kustomize
- IaC: Terraform, Ansible
- DevSecOps: Trivy, Dive, **SOPS** (see [docs/SOPS_GUIDE.md](docs/SOPS_GUIDE.md))
- Editors: LazyVim (Neovim), VSCodium, lazygit
- Modern CLI: eza, bat, delta, ripgrep, fd, fzf, zoxide, starship, atuin

### Security
- UFW firewall (default-deny inbound)
- fail2ban (SSH brute-force protection)
- SSH hardening (pubkey-only, root login disabled)
  - **Note**: `07-post-installation.sh` must run first to set up SSH keys; `03-security.sh` checks for this and prompts before disabling password auth
- AIDE (file integrity monitoring)
- auditd (system audit logging)

### Power Management
- TLP (automatic AC/battery power profiles)
- thermald (thermal throttling daemon)
- Battery charge thresholds: only written on ThinkPad/System76/TUXEDO hardware

### Networking
- WireGuard VPN
- Diagnostics: mtr, traceroute, tcpdump, nmap, tshark, Wireshark
- Modern tools: trippy (better mtr), doggo (better dig)
- Performance: iperf3, speedtest-cli
- Monitoring: nethogs, iftop, vnstat
- DNS: Cloudflare 1.1.1.1 (primary) + Quad9 (fallback), DNSSEC enabled

---

## Architecture

```
debian-setup/
├── setup.sh                           # Main entry point
├── setup-helpers.sh                   # Shared utility library
├── versions.env                       # Pinnable binary versions
├── .env.example                       # Environment config template
├── .chezmoiroot                       # Chezmoi source root → home/
│
├── scripts/
│   ├── 00-base-system.sh             # System foundation + firmware
│   ├── 01-window-manager.sh          # X11: i3, Polybar, Rofi, Dunst
│   ├── 01b-wayland-manager.sh        # Wayland: Sway, Waybar, Wofi, Mako
│   ├── 02-development-tools.sh       # Docker, K8s, languages, modern CLI
│   ├── 03-security.sh                # Firewall, fail2ban, SSH hardening
│   ├── 04-power-management.sh        # TLP, thermald, CPU scaling
│   ├── 05-networking.sh              # VPN, diagnostics, DNS config
│   ├── 06-dotfiles.sh                # Chezmoi dotfiles manager
│   ├── 07-post-installation.sh       # SSH keys, user groups, Git config
│   ├── 08-generate-docs.sh           # Auto-generates System-Reference.md
│   ├── 09-verify.sh                  # Post-install health check
│   └── update-binaries.sh            # Update kubectl, helm, k9s, etc.
│
├── home/                              # Chezmoi source files
│   ├── .chezmoiignore                 # Skips X11 or Wayland configs automatically
│   ├── dot_config/
│   │   ├── i3/                       # i3 config (X11 only)
│   │   ├── sway/                     # Sway config (Wayland only)
│   │   ├── polybar/                  # Polybar (X11 only)
│   │   ├── waybar/                   # Waybar (Wayland only)
│   │   ├── rofi/                     # Rofi launcher (X11 only)
│   │   ├── wofi/                     # Wofi launcher (Wayland only)
│   │   ├── dunst/                    # Notifications (X11 only)
│   │   ├── mako/                     # Notifications (Wayland only)
│   │   ├── kitty/                    # Terminal (shared)
│   │   ├── starship.toml             # Shell prompt (shared)
│   │   ├── btop/                     # System monitor (shared)
│   │   ├── lazygit/                  # Git TUI (shared)
│   │   └── atuin/                    # Shell history (shared)
│   ├── dot_bashrc                    # Bash: aliases, starship, atuin, zoxide
│   ├── dot_zshrc                     # Zsh config
│   └── dot_gitconfig                 # Git: delta pager, histogram diff
│
└── docs/
    ├── QUICK_START.md
    ├── SELECTIONS.md                  # Component rationale
    ├── TROUBLESHOOTING.md
    ├── SOPS_GUIDE.md                  # Secrets management with SOPS + age
    ├── DEBIAN13_COMPATIBILITY.md
    └── CHEZMOI_GUIDE.md
```

---

## Idempotency Guarantee

All scripts are **100% idempotent**:
- Safe to run multiple times
- Skips already-installed packages
- Preserves existing configurations (backs up before modifying)
- Fails loudly with clear error messages

```bash
# Re-run a specific module at any time
sudo bash scripts/04-power-management.sh
```

---

## Version Pinning

By default, tools like `kubectl`, `helm`, and `k9s` are fetched at their latest release. To reproduce a known-good environment, pin versions in `versions.env`:

```bash
# versions.env
KUBECTL_VERSION=v1.30.3
HELM_VERSION=v3.15.2
K9S_VERSION=v0.32.5
```

Override at runtime without editing the file:

```bash
export KUBECTL_VERSION=v1.30.3
sudo -E ./setup.sh
```

---

## Keybindings

### Wayland (Sway) — Super = Windows key

```
Super+Enter      Open Kitty terminal
Super+d          Launch app (Wofi)
Super+Shift+q    Close window
Super+1-9        Switch workspace
Super+h/j/k/l    Navigate windows (vim keys)
Super+f          Fullscreen
Super+Shift+e    Exit Sway
Super+Shift+r    Reload Sway config
```

### X11 (i3) — same bindings, plus:

```
Super+G          Open lazygit in Kitty
Super+Shift+V    Open copyq clipboard history
Print            flameshot screenshot (drag to select)
Super+Shift+M    Multi-monitor interactive setup
```

```
CTRL-R           atuin history TUI (exit code, duration, directory)
```

---

## Security Notes

1. **SSH hardening** (`03-security.sh`) disables password authentication. It checks for at least one sudo user with an existing SSH public key before applying, and prompts for confirmation if none is found. Run `07-post-installation.sh` first.
2. **UFW** defaults to deny all inbound except SSH (22), HTTP (80), HTTPS (443).
3. **fail2ban** bans IPs after 3 failed SSH attempts for 1 hour.
4. **AIDE** baseline is initialized on first run — schedule checks with cron.
5. **SOPS** secrets management: see [docs/SOPS_GUIDE.md](docs/SOPS_GUIDE.md).

---

## Post-Install Commands

```bash
# Health check
sudo bash scripts/09-verify.sh

# Security audit
sudo lynis audit system

# Update binaries (kubectl, helm, k9s, etc.)
bash scripts/update-binaries.sh

# Power status
sudo tlp-stat -p
acpi -b

# Network diagnostics
mtr 8.8.8.8
trip 8.8.8.8          # modern mtr alternative
doggo @1.1.1.1 A example.com
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| [docs/QUICK_START.md](docs/QUICK_START.md) | Step-by-step installation guide |
| [docs/SELECTIONS.md](docs/SELECTIONS.md) | Why each component was chosen |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [docs/SOPS_GUIDE.md](docs/SOPS_GUIDE.md) | Secrets management with SOPS + age |
| [docs/CHEZMOI_GUIDE.md](docs/CHEZMOI_GUIDE.md) | Dotfiles management workflow |
| [docs/DEBIAN13_COMPATIBILITY.md](docs/DEBIAN13_COMPATIBILITY.md) | Debian 13 verification |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design and extensibility |
| System-Reference.md | Auto-generated after install |

---

## Troubleshooting

### Docker permission denied
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### SSH locked out after running 03-security.sh
```bash
# If you have physical access, re-enable password auth temporarily:
sudo rm /etc/ssh/sshd_config.d/90-debian-setup-hardening.conf
sudo systemctl restart ssh
# Then set up SSH keys and re-run 03-security.sh
```

### Wayland / Sway not starting
```bash
# Check seatd or logind is running
systemctl status seatd
# Or try from TTY: sway
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more.

---

## Contributing

1. Test changes on a fresh Debian 12/13 netinstall
2. Maintain idempotency — all scripts must be safe to re-run
3. Document rationale for component choices in [docs/SELECTIONS.md](docs/SELECTIONS.md)
4. Update [versions.env](versions.env) if adding new pinnable binaries

---

## License

MIT — see LICENSE file

---

**Made for IT engineers who live in the terminal.**
