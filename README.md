# Debian Productive Development Environment Setup

An opinionated, idempotent Debian netinstall → productive development workstation in one command.

![Status](https://img.shields.io/badge/status-production-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Debian](https://img.shields.io/badge/distro-Debian%2012+-orange)

## 🎯 Purpose

Transform a minimal Debian netinstall into a **lightweight, secure, productive development environment** optimized for:
- **Software Development**: Go, Python, Node.js, TypeScript
- **DevOps & Cloud**: Docker, Kubernetes, networking tools
- **System Efficiency**: Power management, thermal optimization
- **Security**: Firewall, intrusion detection, SSH hardening
- **Productivity**: Tiling window manager (i3), terminal multiplexing, fuzzy finding

## ✨ Recent Improvements (Mar 2026) - Workspace Modernization

- ✅ **Kitty terminal** - GPU-accelerated, FiraCode ligatures, image protocol (replaces urxvt)
- ✅ **Polybar status bar** - Click-actionable, icon-capable, Catppuccin Mocha themed (replaces i3status)
- ✅ **Starship prompt** - Async git/lang info in shell, cross-shell, Catppuccin Mocha
- ✅ **atuin history** - SQLite shell history with exit codes, duration, directory (replaces CTRL-R)
- ✅ **Modern CLI tools** - eza, bat, delta, btop replacing ls, cat, diff, htop
- ✅ **lazygit** - Visual Git TUI for staging, rebase, cherry-pick (Super+G)
- ✅ **flameshot** - GUI screenshot tool with annotation and clipboard (replaces scrot/maim)
- ✅ **copyq** - Persistent clipboard history across sessions (Super+Shift+V)
- ✅ **Catppuccin Mocha** - Unified color theme across all components
- ✅ **FiraCode Nerd Font** - Icons for polybar, eza, starship (replaces plain FiraCode)
- ✅ **fnm** - Fast Node version manager replacing nvm (10x faster shell startup)
- ✅ **uv** - Ultra-fast Python package manager (10-100x faster than pip)

## ✨ Previous Improvements (Feb 2026)

- ✅ **Parallel installation** - 50-70% faster by running independent modules concurrently
- ✅ **Multi-monitor support** - Auto-detect, profile save/load, home/office switching
- ✅ **Productivity tracking** - ActivityWatch with browser & window watchers
- ✅ **Virtualization** - KVM/QEMU + Vagrant for VM management
- ✅ **Kubernetes UI** - k9s CLI for cluster management
- ✅ **Browser** - Chromium pre-configured and integrated
- ✅ **Binary updates** - Automated update-binaries.sh for kubectl, helm, kind, k9s, ActivityWatch
- ✅ **Fixed dotfiles installation** with Phase 0 verification and automatic relinking

## ✨ Features

| Feature | What's Included |
|---------|-----------------|
| 🪟 **Window Manager** | i3 tiling WM + picom + Polybar + Catppuccin Mocha theme |
| 🖥️ **Terminal** | Kitty (GPU-accelerated, FiraCode ligatures, image protocol) |
| 🎨 **Shell** | Starship prompt + atuin history + Zsh/Bash with 50+ aliases |
| 📁 **CLI Tools** | eza, bat, delta, btop, lazygit replacing dated alternatives |
| 📋 **Clipboard** | copyq persistent clipboard history (Super+Shift+V) |
| 📷 **Screenshots** | flameshot GUI region select + annotation (Print key) |
| 🐳 **Containerization** | Docker + Docker Compose |
| ☸️ **Kubernetes** | kubectl, helm, kind, k9s (local K8s + CLI UI) |
| 🖥️ **Virtualization** | KVM/QEMU + Vagrant for VM management |
| 🐍 **Languages** | Python 3 + uv, Go, Node.js + fnm |
| 🌐 **Browsers** | Chromium (pre-installed & configured) |
| 📊 **Productivity** | ActivityWatch + lazygit TUI (Super+G) |
| 🛡️ **Security** | UFW, fail2ban, AIDE, SSH hardening |
| 🔋 **Power** | TLP, thermald, CPU frequency scaling |
| 🌐 **Networking** | WireGuard, mtr, nmap, tcpdump, iperf3 |
| ✍️ **Editor** | Neovim + delta-enhanced Git diffs |
| ⚡ **Installation** | Parallel execution (50-70% faster) |
| 🔄 **Updates** | Automated binary updates for dev tools |

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/yourusername/debian-setup.git
cd debian-setup

# 2. Run setup (root or sudo required)
sudo ./setup.sh

# 3. Choose installation mode:
#    F = Full installation (all modules)
#    C = Custom selection
#    M = Minimal (base only)

# 4. Post-installation
sudo usermod -aG docker $USER
sudo usermod -aG sudo $USER

# 5. (Optional) Activate multi-monitor setup
~/.config/i3/setup-monitors.sh interactive

# 6. (Optional) Update development binaries
bash update-binaries.sh

# 7. (Optional) Configure ActivityWatch for productivity tracking
~/.local/share/activitywatch/aw-core/aw-server
```

**Installation time**: 
- **Parallel** (default): 15-25 minutes (full) - 50-70% faster!
- **Sequential**: 30-45 minutes (full)
- **Minimal**: 10-15 minutes

## 📋 What Gets Installed

### Tier 1: Base System (Required)
- Linux kernel + firmware (full hardware support)
- Essential build tools (gcc, make, git)
- Core utilities and shell configurations

### Tier 2: Window Manager & Desktop
- **i3** tiling window manager (Catppuccin Mocha borders)
- **picom** compositor (transparency/effects)
- **rofi** application launcher
- **Kitty** terminal (GPU-accelerated, FiraCode ligatures, image protocol)
- **Polybar** status bar (click-actionable, icon-capable, Catppuccin themed)
- **dunst** notification daemon (Catppuccin themed, Nerd Font icons)
- **copyq** clipboard manager (persistent history, image support)
- **flameshot** screenshot tool (GUI region select, annotation)
- **btop** system monitor (all-in-one graphs, mouse support)
- **FiraCode Nerd Font** (icons for polybar, eza, starship)

### Tier 3: Development Tools
- **Languages**: Go, Python 3 + **uv** (fast packaging), Node.js + **fnm** (fast versioning)
- **Containerization**: Docker + Docker Compose
- **Kubernetes**: kubectl, helm, kind (local clusters) + k9s (CLI UI)
- **Virtualization**: KVM/QEMU + Vagrant for VM management
- **Editors**: Neovim + **lazygit** (Git TUI) + **delta** (beautiful diffs)
- **Shell Tools**: **Starship** prompt + **atuin** history + **eza** + **bat** + ripgrep, fd, fzf
- **Productivity**:
  - ActivityWatch (time tracking with watchers)
  - tmux (terminal multiplexing)
- **Browser**: Chromium (pre-configured)

### Tier 4: Security
- UFW firewall with sensible defaults
- fail2ban (intrusion prevention)
- SSH hardening + key authentication
- AIDE (file integrity monitoring)
- auditd (system audit logging)

### Tier 5: Power & Performance
- TLP (automatic power management)
- thermald (thermal management)
- CPU frequency scaling (schedutil governor)
- Power profiling tools (powertop)

### Tier 6: Networking
- WireGuard VPN
- Advanced diagnostics (mtr, tcpdump, nmap)
- Performance testing (iperf3)
- DNS/DHCP tools (dig, dnsmasq)

## 🏗️ Architecture

```
debian-setup/
├── setup.sh                           # Main entry point (parallel orchestrator)
├── setup-helpers.sh                   # Utility functions library
├── install.conf.yaml                  # Dotbot dotfiles configuration (18 symlinks)
├── scripts/                           # Modular installation scripts
│   ├── 00-base-system.sh             # System foundation & kernel
│   ├── 01-window-manager.sh          # i3, Kitty, Polybar, flameshot, copyq, btop
│   ├── 02-development-tools.sh       # Languages, Docker, K8s, VMs, eza/bat/delta/lazygit
│   ├── 03-security.sh                # Firewall, intrusion detection, SSH
│   ├── 04-power-management.sh        # TLP, thermald, governors
│   ├── 05-networking.sh              # VPN, diagnostics, performance
│   ├── 06-dotfiles.sh                # Dotbot symlink manager
│   ├── 07-post-installation.sh       # SSH keys, user groups, finalization
│   ├── generate-i3status-conf.sh     # Legacy: hardware-aware i3status generator (now deprecated)
│   └── update-binaries.sh            # GitHub-based binary updates
├── config/                            # Configuration templates
│   ├── i3/                           # i3 window manager (Catppuccin Mocha)
│   │   ├── config                    # Keybindings, workspaces, multi-monitor
│   │   └── setup-monitors.sh         # Monitor auto-detect & profile manager
│   ├── kitty/                        # Kitty terminal (GPU-accelerated)
│   │   └── kitty.conf                # Font, colors, keybindings (Catppuccin Mocha)
│   ├── polybar/                      # Polybar status bar
│   │   ├── config.ini                # Modules: i3, CPU, temp, memory, battery, network
│   │   └── launch.sh                 # Multi-monitor launch script
│   ├── dunst/                        # Notification daemon
│   │   └── dunstrc                   # Catppuccin Mocha theme, Nerd Font icons
│   ├── btop/                         # System monitor
│   │   └── btop.conf                 # Catppuccin theme, vim keys
│   ├── lazygit/                      # Git TUI
│   │   └── config.yml                # Catppuccin theme, delta integration
│   ├── atuin/                        # Shell history
│   │   └── config.toml               # Local-only, fuzzy search
│   ├── starship.toml                 # Shell prompt (Catppuccin Mocha palette)
│   └── shell/                        # Shell & Git configs
│       ├── .bashrc                   # Aliases: eza, bat, starship, atuin, fnm
│       ├── .zshrc                    # Zsh: starship, atuin, fnm, eza, bat
│       └── .gitconfig                # Git: delta pager, histogram diff
└── docs/
    ├── SELECTIONS.md                 # Component rationale & comparisons
    ├── QUICK_START.md                # Getting started guide
    ├── TROUBLESHOOTING.md            # Common issues & solutions
    ├── DEBIAN13_COMPATIBILITY.md     # Debian 13 verification report
    └── DOTBOT_GUIDE.md               # Dotfiles management guide
```

## 🔄 Idempotency Guarantee

All scripts are **100% idempotent**:
- ✅ Safe to run multiple times
- ✅ Skips already-installed packages
- ✅ Preserves existing configurations
- ✅ Fails loudly with clear errors
- ✅ Backs up critical files before modifications

```bash
# Run setup again to add missing components
sudo ./setup.sh

# Re-run specific module
sudo bash scripts/04-power-management.sh

# No redundancy, no conflicts, same result
```

## 🎮 Usage Examples

### Start Development Cluster
```bash
# Create local Kubernetes cluster
kind create cluster --name dev

# Deploy application
kubectl apply -f deployment.yaml

# View pods
kubectl get pods

# Clean up
kind delete cluster --name dev
```

### Docker Development
```bash
# Build image
docker build -t myapp .

# Run container
docker run -it myapp /bin/bash

# View logs
docker logs myapp
```

### Network Diagnostics
```bash
# Traceroute + ping combined
mtr 8.8.8.8

# Packet capture
sudo tcpdump -i eth0 -n 'tcp port 443'

# Network performance test
iperf3 -s  # Server
iperf3 -c server-ip  # Client
```

### i3 Window Manager
```bash
# Core keybindings
Super+Return     # Open Kitty terminal
Super+d          # Launch app (rofi)
Super+1-0        # Switch workspaces
Super+h/j/k/l    # Focus window (vim keys)
Super+Shift+q    # Close window
Super+f          # Fullscreen
Super+Shift+e    # Exit i3

# New productivity keybindings
Super+G          # Open lazygit in Kitty
Super+Shift+V    # Open copyq clipboard history
Print            # flameshot GUI screenshot (drag to select region)
Super+Print      # Screenshot full screen to clipboard
Super+Shift+M    # Multi-monitor interactive setup

# Shell
CTRL-R           # atuin history TUI (shows exit code, duration, directory)
```

## 📊 System Performance

**Memory (idle i3)**: ~15-20MB
**CPU (power save mode)**: Uses CPU frequency scaling
**Disk space**: ~10GB recommended (full install)
**Boot time**: <15 seconds (SSD)

---

## 🔐 Security Features

1. **Network**: UFW firewall with default-deny policy
2. **Service**: fail2ban monitors SSH for brute-force attempts
3. **SSH**: Public key authentication only, root login disabled
4. **Monitoring**: auditd tracks system changes
5. **Integrity**: AIDE detects unauthorized file modifications

**Security is not a feature, it's a foundation.**

---

## 🔧 Component Selection Rationale

See [SELECTIONS.md](docs/SELECTIONS.md) for detailed explanation of:
- Why these specific tools were chosen
- Comparison with alternatives
- When to use different components
- Performance characteristics

**Key decisions**:
- **i3** over floating WMs (keyboard productivity)
- **Docker** over Podman (ecosystem maturity for K8s)
- **WireGuard** over OpenVPN (modern crypto, simpler)
- **TLP** over laptop-mode (actively maintained)

---

## � Complete Documentation

For detailed information on all aspects of this project, see **[DOCUMENTATION.md](DOCUMENTATION.md)** which provides:
- Quick navigation guide
- Getting started paths for different user types
- Troubleshooting resources
- Component explanations
- Debian 13 compatibility details
- Dotfiles management guide

**Key docs**:
- [QUICK_START.md](docs/QUICK_START.md) - Step-by-step installation
- [SELECTIONS.md](docs/SELECTIONS.md) - Why each component
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design

---

## 📄 License

MIT License - See LICENSE file

---

## ⚡ Inspiration & References

- [i3 Window Manager](https://i3wm.org/) - Tiling WM
- [Docker Documentation](https://docs.docker.com/) - Container platform
- [Kubernetes Docs](https://kubernetes.io/docs/) - Container orchestration
- [Debian Manual](https://www.debian.org/doc/) - OS foundation

---

## 🎓 Learning Path

1. **Understand i3**: Read i3 keybindings, customize config
2. **Master tmux**: Learn terminal multiplexing
3. **Docker basics**: Build and run containers
4. **K8s fundamentals**: Deploy pods, services, deployments
5. **Advanced**: Custom dashboards, CI/CD pipelines

---

## 💬 Support

- **Questions**: Open an issue with `[QUESTION]` tag
- **Bugs**: Report with `[BUG]` tag + system info
- **Suggestions**: Use `[ENHANCEMENT]` tag

**Please include**:
- Debian version (`cat /etc/os-release`)
- Hardware info (`lscpu`, `lsmem`)
- Error logs (`setup-*.log`)

---

**Made with ❤️ for productive developers who love their command line.**

### Modify Without Re-running Setup
Edit shell configs after setup:
```bash
# Shell aliases and functions
~/.bashrc or ~/.zshrc

# i3 window manager keybindings
~/.config/i3/config

# Git global settings
~/.gitconfig

# Power management tuning
/etc/tlp.d/debian-setup.conf
```

### Re-run Setup for Major Changes
```bash
# Install additional module
sudo ./setup.sh
# Choose custom, add modules

# Update all packages
sudo apt update && sudo apt upgrade -y
```

---

## 🐛 Troubleshooting

### Docker Permission Denied
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### i3 Won't Display
```bash
# Ensure X11 is configured
sudo apt install xserver-xorg

# Manually start
startx
```

### SSH Key Issues
```bash
# Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more issues.

---

## 🤝 Contributing

Improvements welcome! Please:
1. Test changes thoroughly
2. Maintain idempotency
3. Document rationale in code comments
4. Update SELECTIONS.md for component changes

---

## 📄 License

MIT License - See LICENSE file

---

## ⚡ Inspiration & References

- [i3 Window Manager](https://i3wm.org/) - Tiling WM
- [Docker Documentation](https://docs.docker.com/) - Container platform
- [Kubernetes Docs](https://kubernetes.io/docs/) - Container orchestration
- [Debian Manual](https://www.debian.org/doc/) - OS foundation

---

## 🎓 Learning Path

1. **Understand i3**: Read i3 keybindings, customize config
2. **Master tmux**: Learn terminal multiplexing
3. **Docker basics**: Build and run containers
4. **K8s fundamentals**: Deploy pods, services, deployments
5. **Advanced**: Custom dashboards, CI/CD pipelines

---

## 💬 Support

- **Questions**: Open an issue with `[QUESTION]` tag
- **Bugs**: Report with `[BUG]` tag + system info
- **Suggestions**: Use `[ENHANCEMENT]` tag

**Please include**:
- Debian version (`cat /etc/os-release`)
- Hardware info (`lscpu`, `lsmem`)
- Error logs (`setup-*.log`)

---

**Made with ❤️ for productive developers who love their command line.**

