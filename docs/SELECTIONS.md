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
├── setup.sh                      # Main orchestrator (entry point)
├── install.conf.yaml             # Dotbot: 18 symlinks managed
├── scripts/
│   ├── 00-base-system.sh        # Kernel, firmware, core packages
│   ├── 01-window-manager.sh     # i3, Kitty, Polybar, Dunst, flameshot, copyq, btop,
│   │                            #   betterlockscreen, FiraCode NF, brightnessctl, PipeWire
│   ├── 02-development-tools.sh  # Docker, K8s, Go, Python+uv, Node+fnm, eza, bat, delta,
│   │                            #   lazygit, Starship, atuin
│   ├── 03-security.sh           # UFW, fail2ban, SSH hardening, AIDE
│   ├── 04-power-management.sh   # TLP, CPU governors, thermal
│   ├── 05-networking.sh         # Network tools, VPN, diagnostics
│   └── 06-dotfiles.sh           # Dotbot: symlink all configs to ~/.config/
├── config/
│   ├── i3/config                # i3 WM: Catppuccin Mocha, Polybar, betterlockscreen
│   ├── kitty/kitty.conf         # GPU terminal: FiraCode NF, Catppuccin Mocha
│   ├── polybar/config.ini       # Status bar: all modules with hardware fallbacks
│   ├── polybar/launch.sh        # Multi-monitor launch
│   ├── starship.toml            # Cross-shell prompt: Catppuccin Mocha
│   ├── atuin/config.toml        # Shell history: SQLite, fuzzy search
│   ├── dunst/dunstrc            # Notifications: Catppuccin Mocha
│   ├── btop/btop.conf           # System monitor: Catppuccin Mocha
│   ├── lazygit/config.yml       # Git TUI: delta pager, Catppuccin Mocha
│   ├── betterlockscreen/        # Lock screen: blur + clock, Catppuccin Mocha
│   └── shell/
│       ├── .bashrc              # Bash: Starship, atuin, fnm, eza/bat aliases
│       ├── .zshrc               # Zsh: Starship, atuin, fnm, eza/bat aliases
│       ├── .gitconfig           # Git: delta pager, histogram diff
│       └── .xinitrc             # X11 startup: exec i3
└── docs/
    ├── SELECTIONS.md            # This file — component rationale
    ├── QUICK_START.md           # Installation and first-use guide
    ├── DEBIAN13_COMPATIBILITY.md# Package compatibility for Debian 12/13
    └── TROUBLESHOOTING.md       # Common issues and fixes
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
5. Pairs with Polybar for a beautiful, icon-capable status bar

**Components:**
- **i3**: Window manager core
- **Polybar**: Feature-rich status bar with Nerd Font icons and click actions
  - **Replaces**: i3status (required restart for changes, no click actions, no icons)
  - **Alternative**: i3status (simpler, still available as fallback)
  - **Alternative**: lemonbar (bare minimum, requires manual scripting)
- **rofi**: Application launcher & window switcher
  - **Alternative**: dmenu (ultra-minimal but less intuitive)
  - **Alternative**: albert (feature-rich but heavier)
- **picom**: Compositor for transparency/shadows
  - **Alternative**: xcompmgr (older, fewer features)
  - **Alternative**: No compositor (saves 5-10MB RAM)
- **Kitty**: GPU-accelerated terminal with ligature support and image protocol
  - **Replaces**: urxvt (software-rendered, no ligatures, no image protocol, aging codebase)
  - **Why Kitty over Alacritty**: Kitty has tabs, splits, image protocol, ligatures. Alacritty is faster at startup but has fewer daily-use features.
  - **Alternative**: Alacritty (faster startup, no tabs/splits/images)
  - **Alternative**: WezTerm (Lua config, built-in multiplexer)
- **flameshot**: Interactive screenshot with GUI selection and annotation
  - **Replaces**: scrot + maim (command-line only, no GUI, no annotation)
  - **Alternative**: scrot (simple, no GUI)
- **copyq**: Persistent clipboard manager with history and search
  - **Adds**: xclip/xsel remain for scripting, copyq provides the history GUI
  - **Alternative**: greenclip (rofi-integrated, lighter)
- **btop**: All-in-one system monitor with CPU/memory/network/disk graphs
  - **Replaces**: htop (process-only view, no graphs, no network/disk)
  - **Alternative**: htop (still available, lighter, process-focused)
- **FiraCode Nerd Font**: Patched font with icons for polybar/eza/starship
  - **Replaces**: Plain FiraCode (no icon glyphs - polybar/eza icons render as boxes)
  - **Installed**: System-wide to `/usr/local/share/fonts/` (not `$HOME` — accessible to all users)
  - **Alternative**: JetBrains Mono Nerd Font (thinner at small sizes)
- **brightnessctl**: Backlight control via `/sys/class/backlight/` (sysfs)
  - **Replaces**: `xbacklight` — xbacklight only works with legacy X11 ACPI backlight; broken on Intel DRM, AMD, NVIDIA, any system using the kernel DRM backlight driver
  - **Why**: Works with `intel_backlight`, `amdgpu_bl`, `nvidia_0`, all firmware-level backlight devices without X11 dependency
  - **Alternative**: `light` (similar, also sysfs-based)
- **PipeWire + pipewire-pulse + pipewire-alsa**: Complete audio stack
  - **Replaces**: Direct `pulseaudio` install — PulseAudio conflicts with PipeWire on Debian 12+
  - **Why**: PipeWire is the default on Debian 12+; `pipewire-pulse` provides a drop-in socket replacement so `pactl` and all PulseAudio clients work unchanged; `pipewire-alsa` bridges the ALSA API so apps that open `/dev/snd` directly (and Chromium internals) still route through PipeWire
  - **Note**: Script auto-detects PipeWire and only installs the compat layer; falls back to PulseAudio on Debian 11 or minimal installs
- **wireplumber**: PipeWire session manager — required for mic routing; without it PipeWire starts but input devices are not connected to applications
- **v4l-utils**: Video4Linux2 userspace interface for webcam devices
  - **Why**: The kernel exposes cameras as `/dev/video*` via the v4l2 subsystem; `v4l-utils` provides the userspace library (`libv4l2`) that Chromium and Firefox link against for camera access; without it, browsers cannot enumerate or open camera devices
  - **Verify**: `v4l2-ctl --list-devices`
- **xdg-desktop-portal + xdg-desktop-portal-gtk**: D-Bus portal stack for mic/camera access
  - **Why**: Chromium (and Firefox) do not access microphone or camera directly on modern desktops — they call `org.freedesktop.portal.Camera` and `org.freedesktop.portal.Microphone` D-Bus interfaces. The portal daemon forwards these to a backend. Without the portal, browsers silently fail permission checks.
  - `xdg-desktop-portal`: base daemon (required for all backends)
  - `xdg-desktop-portal-gtk`: GTK backend — handles camera and mic dialogs; works on both X11 and Wayland
  - `xdg-desktop-portal-wlr`: wlroots backend (Wayland only) — handles screen capture; **does not** handle camera/mic
  - Both WLR and GTK backends coexist and each handles different portal interfaces

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

**Shell & Productivity Tools:**
- **Starship**: Cross-shell prompt with async git/lang/k8s info
  - **Why**: Single Rust binary, 200ms faster than Oh-My-Zsh, works in bash/zsh/fish
  - **Alternative**: Oh-My-Zsh (1000+ files, heavier but more plugins)
  - **Alternative**: Powerlevel10k (zsh-only, complex config)
- **atuin**: Shell history with SQLite backend (replaces CTRL-R)
  - **Why**: Records command + directory + exit code + duration; fuzzy search; no duplicates
  - **Alternative**: fzf-history integration (text-file based, less context)
- **eza**: Modern `ls` replacement with git status, icons, tree mode
  - **Why**: Git column shows modified/untracked/staged files in directory listings
  - **Alternative**: lsd (similar but less actively maintained)
- **bat**: Syntax-highlighted `cat` replacement with git diff integration
  - **Why**: Line numbers, syntax highlighting, shows git changes in margin
  - **Alternative**: highlight (simpler, no git integration)
- **delta**: Side-by-side git diff pager with syntax highlighting
  - **Why**: Git diffs become readable with line numbers and syntax colors
  - **Alternative**: diff-so-fancy (simpler, less configurable)
- **lazygit**: Terminal Git TUI for visual staging and interactive rebase
  - **Why**: Visual hunk-level staging, drag-and-drop rebase, stash management, no git commands memorization needed
  - **Alternative**: tig (read-only browser, less interactive)
  - **Alternative**: vim-fugitive (requires vim, same power inside editor)
- **tmux**: Terminal multiplexer (essential for remote work, terminal sessions)
  - **Alternative**: screen (older, less features)
  - **Alternative**: zellij (modern, Rust-based, fewer plugins)
- **neovim**: Modern Vim fork with better defaults
  - **Alternative**: vim (heavier config needed)
  - **Alternative**: Helix (modern modal editor, tree-sitter native, no plugins needed)
- **ripgrep**: Fast recursive search (10-100x faster than grep)
- **fd**: Fast file finder (better UX than find)
- **fzf**: Fuzzy finder (CTRL-T for file search, integrates with atuin)
- **jq**: JSON query tool (essential for API development)

**Version & Package Managers:**
- **fnm** (Fast Node Manager): Node.js version management
  - **Replaces**: nvm (100ms+ shell startup overhead; fnm adds ~5ms)
  - **Why fnm**: Written in Rust, reads the same `.nvmrc` files, 10x faster startup
  - **Alternative**: nvm (bash-only, slower but more widely documented)
  - **Alternative**: volta (faster, pinned per-project but less .nvmrc compatible)
- **uv**: Ultra-fast Python package manager
  - **Adds**: Drop-in pip replacement; 10-100x faster installs via Rust resolver
  - **Why**: `uv venv` + `uv pip install` replaces slow pip/venv workflow with no behavior change
  - **Alternative**: pip + venv (standard, slower)
  - **Alternative**: poetry (full project management, opinionated)
- **go**: Language-native version management (no separate manager needed)

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

---

### 7. Workspace Theming - Catppuccin Mocha

**Why a unified theme matters:**

Without a theme system, components accumulate mismatched defaults: i3 uses blue (`#285577`), the terminal uses black background, git diffs use red/green only, notifications use system defaults. The result is visual noise that hurts focus.

**Why Catppuccin Mocha:**
- **Dark, not harsh**: Background is `#1e1e2e` (dark blueish), not pure black. Easier on eyes in long sessions.
- **Consistent ecosystem**: Official themes for kitty, polybar, delta, lazygit, btop, starship, nvim, dunst, and 200+ other apps.
- **Pastel accents**: Colors are soft but distinguishable - blue for focus, red for urgent, green for success, mauve for git, without eye strain.
- **Alternative: Nord** (cooler palette, less contrast in some elements, smaller ecosystem)
- **Alternative: Gruvbox** (warm/retro palette, excellent for neovim, fewer modern app themes)
- **Alternative: Tokyo Night** (popular for neovim specifically, fewer non-editor themes)

**Palette reference:**
```
Base     #1e1e2e   Text     #cdd6f4   Blue     #89b4fa
Surface0 #313244   Subtext1 #bac2de   Green    #a6e3a1
Overlay0 #6c7086   Mauve    #cba6f7   Red      #f38ba8
Crust    #11111b   Peach    #fab387   Yellow   #f9e2af
```

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

