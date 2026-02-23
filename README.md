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

## ✨ Recent Improvements (Feb 2026)

- ✅ **Parallel installation** - 50-70% faster by running independent modules concurrently
- ✅ **Multi-monitor support** - Auto-detect, profile save/load, home/office switching
- ✅ **Automatic hardware detection** - i3status config generated for your specific system
- ✅ **Productivity tracking** - ActivityWatch with browser & window watchers
- ✅ **Virtualization** - KVM/QEMU + Vagrant for VM management
- ✅ **Kubernetes UI** - k9s CLI for cluster management
- ✅ **Browser** - Chromium pre-configured and integrated
- ✅ **Binary updates** - Automated update-binaries.sh for kubectl, helm, kind, k9s, ActivityWatch
- ✅ **Fixed dotfiles installation** with Phase 0 verification and automatic relinking
- ✅ **Enhanced error handling** with better logging and recovery

## ✨ Features

| Feature | What's Included |
|---------|-----------------|
| 🪟 **Window Manager** | i3 tiling WM + picom + multi-monitor support |
| 🐳 **Containerization** | Docker + Docker Compose |
| ☸️ **Kubernetes** | kubectl, helm, kind, k9s (local K8s + CLI UI) |
| 🖥️ **Virtualization** | KVM/QEMU + Vagrant for VM management |
| 🐍 **Languages** | Python 3, Go, Node.js |
| 🌐 **Browsers** | Chromium (pre-installed & configured) |
| 📊 **Productivity** | ActivityWatch with browser & window watchers |
| 🛡️ **Security** | UFW, fail2ban, AIDE, SSH hardening |
| 🔋 **Power** | TLP, thermald, CPU frequency scaling |
| 🌐 **Networking** | WireGuard, mtr, nmap, tcpdump, iperf3 |
| ⚙️ **Shell** | Bash & Zsh configs with aliases |
| ✍️ **Editor** | Neovim + Git configuration |
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
- **i3** tiling window manager
- **picom** compositor (transparency/effects)
- **rofi** application launcher
- Terminal emulator (urxvt/xterm)
- Status bar (i3status)
- Notification daemon

### Tier 3: Development Tools
- **Languages**: Go, Python 3, Node.js runtimes
- **Containerization**: Docker + Docker Compose
- **Kubernetes**: kubectl, helm, kind (local clusters) + k9s (CLI UI)
- **Virtualization**: KVM/QEMU + Vagrant for VM management
- **Editors**: Neovim + Git with signing keys
- **Productivity**: 
  - ActivityWatch (time tracking with watchers)
  - tmux (terminal multiplexing), fzf, ripgrep, fd (productivity tools)
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
├── install.conf.yaml                  # Dotbot dotfiles configuration
├── scripts/                           # Modular installation scripts
│   ├── 00-base-system.sh             # System foundation & kernel
│   ├── 01-window-manager.sh          # i3 + compositor + browser
│   ├── 02-development-tools.sh       # Languages, Docker, K8s, VMs, tools
│   ├── 03-security.sh                # Firewall, intrusion detection, SSH
│   ├── 04-power-management.sh        # TLP, thermald, governors
│   ├── 05-networking.sh              # VPN, diagnostics, performance
│   ├── 06-dotfiles.sh                # Dotbot symlink manager
│   ├── 07-post-installation.sh       # SSH keys, user groups, finalization
│   ├── generate-i3status-conf.sh     # Hardware-aware i3status generator
│   └── update-binaries.sh            # GitHub-based binary updates
├── config/                            # Configuration templates
│   ├── i3/                           # i3 window manager
│   │   ├── config                    # Keybindings, workspaces, multi-monitor
│   │   └── setup-monitors.sh         # Monitor auto-detect & profile manager
│   └── shell/                        # Shell & Git configs
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
# After startx, key bindings:
Super+Return     # Open terminal
Super+d          # Launch app
Super+1-0        # Switch workspaces
Super+h/j/k/l    # Focus window (vim keys)
Super+Shift+q    # Close window
Super+f          # Fullscreen
Super+Shift+e    # Exit i3
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

