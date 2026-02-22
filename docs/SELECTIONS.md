# Debian Setup - Architecture & Selection Guide

## Overview

This repository provides an idempotent, modular installation system for a productive Debian-based development environment optimized for:
- **Coding**: Go, Python, Node.js, TypeScript
- **Containerization**: Docker, Kubernetes (kubectl, helm, kind)
- **Networking**: Advanced diagnostics, VPN, performance testing
- **System Performance**: Power efficiency with on-demand performance
- **Security**: Hardware-backed security, intrusion detection
- **Desktop Environment**: Lightweight tiling window manager (i3)

All scripts follow idempotent principles - running them multiple times produces the same result without harm or redundancy.

---

## System Architecture

```
debian-setup/
├── setup.sh                    # Main orchestrator (entry point)
├── scripts/
│   ├── 00-base-system.sh      # Kernel, firmware, core packages
│   ├── 01-window-manager.sh   # i3 WM, compositor, terminal
│   ├── 02-development-tools.sh# Languages, Docker, K8s tools
│   ├── 03-security.sh         # Firewall, fail2ban, SSH hardening
│   ├── 04-power-management.sh # TLP, CPU governors, thermal
│   └── 05-networking.sh       # Network tools, VPN, diagnostics
├── config/
│   ├── i3/
│   │   ├── config             # i3 window manager config
│   │   └── i3status.conf      # Status bar configuration
│   └── shell/
│       ├── .bashrc            # Bash shell configuration
│       ├── .zshrc             # Zsh shell configuration
│       └── .gitconfig         # Git global configuration
└── docs/
    ├── SELECTIONS.md          # This file
    ├── QUICK_START.md         # Quick start guide
    └── TROUBLESHOOTING.md     # Common issues
```

---

## Component Selection Rationale

### 1. Base System (00-base-system.sh)

**Why Debian?**
- Stable, predictable release cycle
- Excellent hardware support
- Large community and long-term support
- Lightweight and customizable

**Kernel Selection:**
- **Choice**: `linux-image-generic` (default generic kernel)
- **Rationale**: Best hardware compatibility across diverse systems
- **Alternatives**:
  - `linux-image-cloud`: Cloud-only deployments (limited driver support)
  - `linux-image-rt`: Real-time systems (rarely needed for dev work)
  - Custom kernel: Overkill for most use cases

**Bootloader:**
- **Choice**: systemd-boot (built-in with modern systemd)
- **Rationale**: Minimal, UEFI-native, fast
- **Alternatives**:
  - GRUB2: More features but heavier (≈20MB vs ≈2MB)
  - rEFInd: Mac-like interface, more complex

**Core Packages:**
- Build tools (gcc, g++, make): Compile source code
- linux-headers: Kernel module development (Docker, VirtualBox, etc.)
- Firmware packages: Complete hardware support (Intel µcode, AMD µcode)
- Development essentials: Git, curl, wget, vim

---

### 2. Window Manager (01-window-manager.sh)

**Why i3?**
- Extremely lightweight (minimal memory footprint)
- Tiling WM: Maximize screen real estate, perfect for terminals/code
- Keyboard-centric workflow: No mouse needed for power users
- Highly customizable via config files
- Excellent for multi-monitor setups (common in dev environments)

**Detailed Comparison:**

| Feature | i3 | Openbox | dwm | xmonad | awesome |
|---------|-----|---------|-----|---------|---------|
| Tiling | Yes | No | Yes | Yes | Yes |
| Memory | ~15MB | ~10MB | ~5MB | ~20MB | ~50MB |
| Config | Text | XML | Recompile | Haskell | Lua |
| Learning Curve | Easy | Easy | Medium | Hard | Medium |
| Community | Large | Medium | Small | Medium | Large |
| Hardware Focus | Yes | No | Yes | No | No |

**Why i3 wins for this use case:**
1. Keyboard-focused (productivity boost)
2. Lightweight enough for older hardware
3. Trivial configuration (text files, no recompilation)
4. Perfect for coding: split terminals, quick window switching
5. Excellent i3status bar (lightweight alternative to polybar)

**Components:**
- **i3**: Window manager core
- **i3status**: Minimal status bar (lightweight, responsive)
  - **Alternative**: polybar (heavier, more features)
  - **Alternative**: lemonbar (bare minimum, requires manual scripting)
- **rofi**: Application launcher & window switcher
  - **Alternative**: dmenu (ultra-minimal but less intuitive)
  - **Alternative**: albert (Electron-based, heavier)
- **picom**: Compositor for transparency/shadows
  - **Alternative**: xcompmgr (older, fewer features)
  - **Alternative**: No compositor (saves 5-10MB RAM)
- **urxvt**: Terminal emulator
  - **Alternative**: xterm (minimal, less modern)
  - **Alternative**: alacritty (requires Rust, GPU-accelerated but heavier)
  - **Alternative**: kitty (Python-based, good Unicode support)

---

### 3. Development Tools (02-development-tools.sh)

**Language Choices:**
- **Go**: Systems programming, cloud native tools (Kubernetes is written in Go)
- **Python 3**: Data science, DevOps, automation, scripting
- **Node.js**: Frontend, JavaScript tooling, full-stack development

**Containerization:**
- **Docker**: Industry standard, excellent K8s integration
  - **Alternative**: Podman (more secure, better for rootless operations, but smaller ecosystem)
  - **Alternative**: LXC (container technology but not Docker-compatible)

**Kubernetes Tools:**
- **kubectl**: Official K8s CLI (required)
- **kind**: Lightweight local K8s clusters in Docker (perfect for testing)
  - **Alternative**: minikube (heavier, more features but slower)
  - **Alternative**: k3s (edge-focused, good for resource-constrained)
- **helm**: Kubernetes package manager (standard for deployments)

**Productivity Tools:**
- **tmux**: Terminal multiplexer (essential for remote work, terminal sessions)
  - **Alternative**: screen (older, less features)
  - **Alternative**: zellij (modern, Rust-based, fewer plugins)
- **neovim**: Modern Vim fork with better defaults
  - **Alternative**: vim (heavier config needed)
  - **Alternative**: nano (too basic for code editing)
- **ripgrep**: Fast recursive search (10-100x faster than grep)
- **fd**: Fast file finder (better UX than find)
- **fzf**: Fuzzy finder (CTRL-T for file search, CTRL-R for history)
- **jq**: JSON query tool (essential for API development)

**Version Managers:**
- **nvm**: Node version manager (manage multiple Node.js versions)
- **pyenv**: Python version manager (manage multiple Python versions)
- **go**: Language-native (no separate manager needed)

---

### 4. Security (03-security.sh)

**Firewall:**
- **Choice**: ufw (Uncomplicated Firewall)
- **Rationale**: Simple, sane defaults, perfect for developers
- **Alternatives**:
  - iptables: Powerful but complex CLI (ufw wraps this)
  - firewalld: Zone-based, heavier, requires systemd integration

**Intrusion Prevention:**
- **Choice**: fail2ban
- **Rationale**: Monitors logs, automatically bans brute-force attempts
- **Functionality**:
  - Monitors SSH failed login attempts
  - Temporary IP bans after N failures
  - Integrates with firewall automatically
- **Alternative**: denyhosts (legacy, no longer maintained)

**SSH Hardening:**
- Disable root login
- Public key authentication only
- Disable password authentication
- Disable X11 forwarding (unless needed)
- SSH keys: Ed25519 > ECDSA > RSA (in terms of modern crypto)

**File Integrity:**
- **AIDE** (Advanced Intrusion Detection Environment)
- **Purpose**: Detect unauthorized file modifications
- **Use case**: Verify system binaries haven't been tampered with

**Audit Daemon:**
- **auditd**: System auditing, tracks file/process changes
- **Use case**: Forensics, compliance, detecting suspicious activity

---

### 5. Power Management (04-power-management.sh)

**Key Component: TLP**
- Automatic power management based on AC/battery
- CPU frequency scaling: Save power when idle, boost when needed
- Disk spindown management
- USB autosuspend
- Thermal management coordination

**CPU Governors:**

| Governor | AC Behavior | Battery Behavior | Use Case |
|----------|-------------|------------------|----------|
| schedutil | Responsive | Balanced | **Recommended** - Kernel-aware |
| performance | Max frequency | Max frequency | Benchmarking |
| powersave | Min frequency | Min frequency | Maximum battery life |
| ondemand | On-demand boost | Conservative | Legacy systems |

**Thermal Management:**
- **thermald**: Monitors temperature, throttles if needed
- **Purpose**: Prevent overheating, extend hardware life
- Especially important on laptops and fanless systems

**Battery Thresholds (ThinkPad/System76):**
- Start charging at 20%
- Stop charging at 80%
- **Rationale**: Extends battery lifespan (lithium-ion prefers partial charges)

---

### 6. Networking (05-networking.sh)

**VPN Solution:**
- **Choice**: WireGuard
- **Why**: Modern crypto, minimal dependencies, excellent performance
- **Alternatives**:
  - OpenVPN: Mature but heavier configuration
  - IPSec: Complex, harder to debug
  - Tailscale: WireGuard-based, managed service (SaaS)

**Diagnostic Tools:**
- **mtr**: Combined ping + traceroute (better visualization than separate tools)
- **tcpdump**: Low-level packet capture
- **nmap**: Network scanning, security testing
- **tshark**: Terminal Wireshark (packet analysis)

**Performance Testing:**
- **iperf3**: Network throughput testing
- **speedtest-cli**: Internet speed testing

**DNS:**
- **Cloudflare DNS** (1.1.1.1): Fast, privacy-focused
- **Quad9** (9.9.9.9): Security-focused, blocks malware

---

## Idempotency Guarantees

All scripts follow these principles:

1. **Atomic Operations**: Each step checks if already done
2. **No State Assumptions**: Scripts work whether run 1st or 10th time
3. **Backups**: Critical configs backed up before modification
4. **Error Handling**: Fails loudly with clear error messages
5. **Conditional Execution**: Uses `if ! command -v` before installing

Example pattern:
```bash
if ! command -v docker &> /dev/null; then
    # Install Docker only if not already installed
    apt-get install -y docker-ce
else
    log_warn "Docker already installed"
fi
```

---

## Performance Characteristics

**Base System**: ~500MB minimal, ~2-3GB full installation

**Memory Usage** (running):
- Bare i3 WM: ~15MB
- i3 + terminal: ~50MB
- i3 + terminal + Firefox: ~500MB+

**CPU Overhead**:
- TLP power management: <1% CPU
- Thermal daemon: <0.5% CPU
- fail2ban: <0.1% CPU

---

## Security Model

1. **Defense in Depth**:
   - Firewall (network layer)
   - fail2ban (service layer)
   - SSH hardening (application layer)
   - File integrity (filesystem layer)

2. **Principle of Least Privilege**:
   - Root access minimized
   - User isolation enforced
   - Docker runs as non-root when possible

3. **Audit Trail**:
   - auditd logs system changes
   - SSH logs all connection attempts
   - fail2ban records suspicious activity

---

## Customization Points

### Easily Configurable:
- **Shell aliases**: Edit `~/.bashrc` or `~/.zshrc`
- **i3 keybindings**: Edit `~/.config/i3/config`
- **Git config**: Edit `~/.gitconfig`
- **TLP power settings**: Edit `/etc/tlp.d/debian-setup.conf`

### Requires Code Changes:
- Adding languages/tools: Edit `02-development-tools.sh`
- Changing WM: Replace entire `01-window-manager.sh`
- Different firewall rules: Edit `03-security.sh`

---

## When to Use Alternatives

**Switch to Openbox if:**
- You prefer floating windows
- You don't use keyboard much
- You want XFCE-like experience
- You need traditional menu-based interface

**Switch to dwm if:**
- You want absolute minimal resource usage
- You're comfortable recompiling C code for changes
- You like suckless philosophy

**Switch to Podman if:**
- You need rootless container operation
- Your infrastructure runs Podman instead of Docker
- You want tighter security isolation

**Use minikube instead of kind if:**
- You need actual hypervisor (not Docker-in-Docker)
- You're on ARM/M1 Mac (limited Docker support)
- You need more K8s features tested

---

## References

- [i3 Window Manager](https://i3wm.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [WireGuard VPN](https://www.wireguard.com/)
- [TLP Power Management](https://linrunner.de/en/tlp/index.html)
- [fail2ban Documentation](https://www.fail2ban.org/)

