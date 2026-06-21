# Debian Setup - Repository Structure Documentation

## Project Layout

```
debian-setup/
│
├── README.md                     # Main project documentation
├── ARCHITECTURE.md               # This file - system design & structure
├── DOCUMENTATION.md              # Documentation guide
├── setup.sh                      # Entry point (parallel orchestrator)
├── setup-helpers.sh              # Utility functions library
├── .chezmoiroot                  # Mount point config for Chezmoi
│
├── scripts/                      # Modular installation scripts (numbered order)
│   ├── 00-base-system.sh        # [1] Core system setup (kernel, firmware, build tools)
│   ├── 01-window-manager.sh     # [2] Legacy X11: i3, Kitty, Polybar, flameshot
│   ├── 01b-wayland-manager.sh   # [2b] Modern Wayland: Sway, Waybar, Wofi, grim
│   ├── 02-development-tools.sh  # [3] Dev tools: Docker, K8s, LazyVim, zoxide
│   ├── 03-security.sh           # [4] Security hardening (UFW, fail2ban, SSH)
│   ├── 04-power-management.sh   # [5] Power & thermal management (TLP, thermald)
│   ├── 05-networking.sh         # [6] Network tools & VPN (WireGuard, mtr, nmap)
│   ├── 06-dotfiles.sh           # [7] Chezmoi dotfiles manager (copies configs into $HOME)
│   ├── 07-post-installation.sh  # [8] Post-setup (SSH keys, user groups, finalization)
│   ├── 08-generate-docs.sh      # [9] Generate documentation
│   ├── 09-verify.sh             # [10] Verify installation
│   └── update-binaries.sh       # Binary update manager
│
├── home/                         # Configuration templates (mapped via Chezmoi)
│   ├── dot_config/
│   │   ├── i3/                  # i3 window manager (Catppuccin Mocha theme)
│   │   ├── sway/                # Sway window manager
│   │   ├── kitty/               # Kitty terminal (GPU-accelerated)
│   │   ├── polybar/             # Polybar status bar
│   │   ├── waybar/              # Waybar status bar
│   │   ├── dunst/               # Notification daemon
│   │   ├── btop/                # System monitor (replaces htop)
│   │   ├── lazygit/             # Git TUI
│   │   ├── atuin/               # Shell history (replaces CTRL-R)
│   │   └── starship.toml        # Shell prompt (Catppuccin Mocha palette)
│   ├── dot_bashrc               # Bash: zoxide, eza, starship, fnm
│   ├── dot_zshrc                # Zsh: zoxide, starship, fnm
│   ├── dot_gitconfig            # Git: delta pager, histogram diff
│   └── dot_xinitrc              # X11 startup
│
├── docs/                         # Documentation directory
│   ├── QUICK_START.md           # Getting started guide with examples
│   ├── SELECTIONS.md            # Component rationale & comparison
│   ├── TROUBLESHOOTING.md       # 40+ common issues & solutions
│   ├── DEBIAN13_COMPATIBILITY.md# Debian 13 verification report
│   └── CHEZMOI_GUIDE.md         # Dotfiles management guide
│
└── [Future: tests/]             # Test suite
```

## File Purposes

### Root Level Files

| File | Purpose |
|------|---------|
| `setup.sh` | Main entry point - orchestrates all modules |
| `setup-helpers.sh` | Utility functions - logging, checks, helpers |
| `.env.example` | Template for environment configuration |
| `.gitignore` | Git ignore patterns - excludes logs, backups |
| `README.md` | Project overview, quick start, features |

### Scripts Directory (`scripts/`)

Each script is **independently executable** and **fully idempotent**:

| Script | Purpose | Key Components |
|--------|---------|-----------------|
| `00-base-system.sh` | Kernel, firmware, build tools | Linux kernel (generic), gcc, make, git, curl |
| `01-window-manager.sh` | Legacy X11 desktop | i3, picom, rofi, lightdm, **Kitty**, **Polybar**, **flameshot**, **copyq**, **btop**, FiraCode Nerd Font |
| `01b-wayland-manager.sh` | Modern Wayland desktop (default) | Sway, **Waybar**, Wofi, grim, slurp, PipeWire |
| `02-development-tools.sh` | Dev stack & tools | Languages (Go, Python+**uv**, Node.js+**fnm**), Docker, K8s, KVM/Vagrant, **eza**, **bat**, **delta**, **lazygit**, **Starship**, **atuin** |
| `03-security.sh` | Security hardening | UFW firewall, fail2ban, SSH hardening, AIDE |
| `04-power-management.sh` | Power & thermal | TLP, thermald, CPU scaling, powertop |
| `05-networking.sh` | Network tools | WireGuard, mtr, tcpdump, nmap, dig, iperf3 |
| `06-dotfiles.sh` | Dotfiles manager | chezmoi install + `chezmoi --source <repo> apply` (copies configs into `$HOME`); X11/Wayland selected via `home/.chezmoiignore` |
| `07-post-installation.sh` | Post-setup tasks | SSH keys, user groups, shell selection |
| `08-generate-docs.sh` | Documentation generation | Generates docs from the installed system |
| `09-verify.sh` | Installation verification | Verifies installed packages, services, and configs |
| `update-binaries.sh` | Binary updates | GitHub API for kubectl, helm, k9s, ActivityWatch version checking |

### Config Directory (`home/dot_config/`)

Pre-configured files managed by chezmoi and copied into the user's home (chezmoi naming: `dot_config/` → `~/.config/`, `dot_bashrc` → `~/.bashrc`). All follow Catppuccin Mocha theme:

```
home/
├── dot_config/
│   ├── i3/
│   │   ├── config                 # i3: Catppuccin Mocha borders, Kitty terminal, Polybar exec
│   │   └── setup-monitors.sh      # Monitor auto-detect & xrandr profile manager
│   │
│   ├── kitty/
│   │   └── kitty.conf             # GPU terminal: FiraCode Nerd Font, Catppuccin Mocha, ligatures
│   │
│   ├── polybar/
│   │   ├── config.ini             # Modules: i3 workspaces, CPU/temp/mem/battery/network/audio
│   │   └── launch.sh              # Multi-monitor polybar launcher
│   │
│   ├── dunst/
│   │   └── dunstrc                # Notifications: Catppuccin Mocha, corner_radius=8, Nerd Font
│   │
│   ├── btop/
│   │   └── btop.conf              # System monitor: Catppuccin theme, vim keys, all panels
│   │
│   ├── lazygit/
│   │   └── config.yml             # Git TUI: Catppuccin, delta integration, vim navigation
│   │
│   ├── atuin/
│   │   └── config.toml            # History: local SQLite, fuzzy search, secret filtering
│   │
│   └── starship.toml              # Prompt: Catppuccin Mocha palette, async git/lang/k8s info
│
├── dot_bashrc                     # Bash: eza/bat aliases, starship init, atuin init, fnm
├── dot_zshrc                      # Zsh: starship, atuin, fnm init, eza/bat aliases
├── dot_gitconfig                  # Git: delta pager, side-by-side diffs, histogram algorithm
└── dot_xinitrc                    # X11 startup: xset keyboard rate, xrdb merge, exec i3
```

### Docs Directory (`docs/`)

Comprehensive documentation for users:

| Document | Content |
|----------|---------|
| `QUICK_START.md` | Step-by-step setup guide, post-install configuration, examples |
| `SELECTIONS.md` | Component rationale, pros/cons, alternative tool comparisons |
| `TROUBLESHOOTING.md` | 40+ common issues, solutions, debugging tips, error messages |
| `DEBIAN13_COMPATIBILITY.md` | Debian 13 verification report, compatibility details |
| `CHEZMOI_GUIDE.md` | Dotfiles management with chezmoi, workflows, X11/Wayland selection |
| `ARCHITECTURE.md` | Deep dive into system design, extensibility, customization (this file) |
| `DOCUMENTATION.md` | Navigation guide for all documentation files |

---

## Execution Flow

### Parallel Installation (Default - 50-70% Faster!)

1. **Pre-flight Checks**
   - Verify root/sudo permission
   - Check all scripts exist
   - Test internet connectivity
   - Verify disk space

2. **User Chooses Mode**
   - **Full** (F) - All modules with parallel execution
   - **Minimal** (M) - Base system only
   - **Custom** (C) - Pick and choose modules

3. **Execute Modules Concurrently**
   ```
   00-base-system.sh (runs sequentially first - required)
   ├─ Then in parallel:
   │  ├─> 01-window-manager.sh
   │  ├─> 02-development-tools.sh  
   │  ├─> 03-security.sh
   │  ├─> 04-power-management.sh
   │  └─> 05-networking.sh
   └─ Then sequential:
      ├─> 06-dotfiles.sh
      └─> 07-post-installation.sh
   ```

4. **Post-Installation Steps**
   - Apply dotfiles via chezmoi (`chezmoi --source <repo> apply` copies configs into `$HOME`)
   - Select X11 vs Wayland configs via `home/.chezmoiignore` (driven by `display_server`)
   - Prompt user to add to groups (docker, libvirt, etc)
   - Show next steps (ActivityWatch, multi-monitor setup)

### Sequential Execution (Legacy - Slower but Safer)

If running individual scripts or using sequential mode:
```bash
bash scripts/00-base-system.sh
bash scripts/01-window-manager.sh      # X11 (i3); or 01b-wayland-manager.sh for Sway (default)
bash scripts/02-development-tools.sh
bash scripts/03-security.sh
bash scripts/04-power-management.sh
bash scripts/05-networking.sh
bash scripts/06-dotfiles.sh
bash scripts/07-post-installation.sh
bash scripts/update-binaries.sh  # Optional later
```

### Idempotency Checks

Each script contains patterns like:

```bash
# Installation check
if ! command -v docker &> /dev/null; then
    # Only install if not present
    apt-get install docker-ce
else
    log_warn "Docker already installed"
fi

# Configuration check  
if ! grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    # Only modify if not already set
    sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
fi

# File backup before modification
backup_file /etc/ssh/sshd_config
```

---

## Special Features & Implementation

### 1. Parallel Installation (setup.sh)

**What**: Runs independent installation modules concurrently using bash background jobs.

**How**: 
```bash
run_script_parallel() {
    { ... script execution ... } &
}
# Collect all background job results with 'wait'
wait
```

**Speed Gain**: 50-70% faster installation time (15-25 min vs 30-45 min)

**Files Involved**: 
- [setup.sh](setup.sh) - `run_script_parallel()` function
- Independent scripts (01-05) - Can run simultaneously

---

### 2. Polybar Status Bar (replaces i3status)

**What**: Beautiful, icon-capable, click-actionable status bar with automatic hardware detection.

**Advantages over i3status**:
- Click actions: click battery → pavucontrol, click volume → mute, click workspace → switch
- Nerd Font icons: battery, temperature, wifi signal strength, volume icons
- No restart needed: `polybar --reload` applies changes in-place
- Auto-detects thermal zones at runtime (no generation script needed)
- Catppuccin Mocha themed natively via `[colors]` section

**Modules configured** (`config/polybar/config.ini`):
- `i3` - Clickable workspace buttons
- `xwindow` - Active window title
- `cpu` - CPU percentage
- `temperature` - CPU temperature with icons
- `memory` - RAM usage
- `battery` - Battery with charging animation
- `network` - Auto-detect WiFi/Ethernet signal + IP (`interface-type = any`)
- `pulseaudio` - Volume via PipeWire-pulse compat layer (or legacy PulseAudio); click → pavucontrol
- `temperature` - CPU temp with graceful `──°C` fallback when no sensor (VM/desktop)
- `battery` - Charging animation; shows plug icon fallback on desktop (no BAT0)
- `date` - Date and time

**Files Involved**:
- [config/polybar/config.ini](config/polybar/config.ini) - Main polybar configuration
- [config/polybar/launch.sh](config/polybar/launch.sh) - Multi-monitor launch script
- [config/i3/config](config/i3/config) - `exec_always ~/.config/polybar/launch.sh`

**Note**: On X11 the status bar is Polybar (configured via the dotfiles in `home/dot_config/polybar/`); on Wayland it is Waybar. Neither is generated by a script — both are managed by chezmoi.

---

### 3. Multi-Monitor Support (setup-monitors.sh)

**What**: Detect monitors, create configurations, save/load profiles for home/office.

**Features**:
- **Auto-detect**: Lists all connected/disconnected monitors
- **Auto-configure**: Single monitor or extend right (default)
- **Interactive**: Menu for extend right/left/above/below, mirror
- **Profiles**: Save current layout as named profile (home, office)
- **Hotplug**: Automatic on system startup via i3 exec

**How**:
```bash
~/.config/i3/setup-monitors.sh auto          # Auto-configure
~/.config/i3/setup-monitors.sh interactive   # Interactive menu
~/.config/i3/setup-monitors.sh save home     # Save as 'home' profile
~/.config/i3/setup-monitors.sh load office   # Load 'office' profile
```

**Implementation**:
- Uses `xrandr` for monitor detection and configuration
- Stores profiles in `~/.config/i3/monitor-profiles/`
- Integrated with i3 keybindings (Super+Shift+M/N)

**Files Involved**:
- [config/i3/setup-monitors.sh](config/i3/setup-monitors.sh) - Main script
- [config/i3/config](config/i3/config) - Keybindings and startup exec
- `~/.config/i3/monitor-profiles/` - User profile storage (created at runtime)

---

### 4. Productivity Tracking (ActivityWatch)

**What**: Track active window and time spent per application.

**Components**:
- **aw-server**: Central database daemon
- **aw-watcher-window**: Active window tracking
- **aw-watcher-web**: Browser tab tracking (Chrome extension)

**Installation**:
```bash
# Installed by scripts/02-development-tools.sh
# Version: 0.12.2
# Location: ~/.local/share/activitywatch/
```

**Systemd Service**:
```bash
# Enabled as user service (no sudo required)
systemctl --user enable activitywatch
systemctl --user start activitywatch
```

**Files Involved**:
- [scripts/02-development-tools.sh](scripts/02-development-tools.sh) - Section 11: Installation
- [scripts/update-binaries.sh](scripts/update-binaries.sh) - Version checking & updates

---

### 5. Catppuccin Mocha Unified Theme

**What**: A consistent dark color palette applied across all visual components.

**Components themed**:

| Component | Config File | Theme Application |
|-----------|-------------|-------------------|
| i3 window borders | `config/i3/config` | Blue focused border, dark inactive |
| Polybar | `config/polybar/config.ini` | Full `[colors]` palette |
| Kitty terminal | `config/kitty/kitty.conf` | 16 terminal colors + UI colors |
| dunst notifications | `config/dunst/dunstrc` | Background/frame/text per urgency |
| btop | `config/btop/btop.conf` | `color_theme = catppuccin_mocha` |
| lazygit | `config/lazygit/config.yml` | Border/selection/text colors |
| Starship prompt | `config/starship.toml` | Named `catppuccin_mocha` palette |
| delta git diffs | `config/shell/.gitconfig` | `syntax-theme = Catppuccin Mocha` |

**Core Palette**:
```
Base:    #1e1e2e  Mantle:  #181825  Crust:   #11111b
Blue:    #89b4fa  Green:   #a6e3a1  Red:     #f38ba8
Mauve:   #cba6f7  Peach:   #fab387  Yellow:  #f9e2af
Text:    #cdd6f4  Surface: #313244  Overlay: #6c7086
```

**Files Involved**: All files under `config/` directory

---

### 6. Binary Update Manager (update-binaries.sh)

**What**: Check and update development binaries from GitHub releases.

**Managed Binaries**:
- `kubectl` - Kubernetes CLI
- `helm` - Kubernetes package manager
- `kind` - Local Kubernetes clusters
- `k9s` - Kubernetes cluster UI
- `activitywatch` - Productivity tracker

**How It Works**:
```bash
get_latest_release() {
    # Query GitHub API v3 for latest release tag
    # Example: derailed/k9s -> v0.50.18
}

version_gt() {
    # Semantic version comparison using 'sort -V'
}

# Check, compare, and update if newer version available
```

**Usage**:
```bash
bash scripts/update-binaries.sh
# Output shows current vs latest version for each tool
# Automatically downloads and installs if newer available
```

**Files Involved**:
- [scripts/update-binaries.sh](scripts/update-binaries.sh) - Main update script

---

## Configuration Hierarchy

Users can configure at multiple levels:

### Level 1: Template Configs (After Installation)
```bash
# Copy pre-made configs to user home
cp config/i3/config ~/.config/i3/config
cp config/shell/.bashrc ~/.bashrc
cp config/shell/.zshrc ~/.zshrc
```

### Level 2: User Customization
```bash
# Users edit their copies
~/.config/i3/config              # i3 keybindings
~/.bashrc / ~/.zshrc             # Shell aliases
~/.gitconfig                     # Git settings
/etc/tlp.d/debian-setup.conf    # Power management
```

### Level 3: System-Wide Defaults
```bash
/etc/apt/sources.list           # Package repositories
/etc/ssh/sshd_config            # SSH settings
/etc/ufw/ufw.conf               # Firewall rules
```

---

## Extensibility

### Adding New Modules

1. Create `scripts/06-new-module.sh` following existing patterns
2. Update `setup.sh` to include new module
3. Add documentation in `docs/SELECTIONS.md`
4. Test idempotency: run script twice

### Customizing for Teams

Create organization-specific fork:
```bash
# Modify scripts for your team's preferences
# Update default configurations
# Host on private Git server or GitHub

# Teams clone and run
git clone https://internal-git/company/debian-setup.git
sudo ./setup.sh
```

---

## Performance Characteristics

### Installation Time
- **Minimal**: 10-15 min (base system only)
- **Full**: 30-45 min (all modules, includes language downloads)
- **Partial**: 15-30 min (custom selection)

### Disk Space Usage
- **Minimal**: ~2-3 GB
- **Full**: ~8-10 GB (includes Docker images, language runtimes)
- **Break down**:
  - Base system: ~1 GB
  - Languages: ~2 GB (Go+Python+Node.js)
  - Docker: ~2 GB
  - Development tools: ~1 GB
  - Window manager: ~500 MB

### Runtime Memory (Idle)
- **i3 Window Manager**: 15-20 MB
- **Power Management (TLP)**: <1 MB
- **Security (fail2ban)**: <5 MB
- **Kubernetes tools**: On-demand (0 MB idle)

---

## Security Model

### Layers of Security

1. **Network (UFW Firewall)**
   - Denies inbound by default
   - Allows SSH, HTTP, HTTPS
   - Application-specific rules

2. **Service (fail2ban)**
   - Monitors SSH for brute-force
   - Automatic IP banning
   - Configurable threshold

3. **Application (SSH Hardening)**
   - Public key auth only
   - Root login disabled
   - X11 forwarding disabled

4. **System (Auditing)**
   - auditd logs changes
   - AIDE detects tampering
   - System logs retained

### Principle of Least Privilege
- Services run as minimal user
- Docker runs non-root when possible
- Development tools don't require root
- Power management runs as service

---

## Testing Strategy (Future)

```
tests/
├── test-base-system.sh         # Verify kernel, firmware, tools
├── test-window-manager.sh      # Verify i3 installation
├── test-development-tools.sh   # Verify languages, Docker, K8s
├── test-security.sh            # Verify firewall, fail2ban
├── test-power-management.sh    # Verify TLP, CPU scaling
├── test-networking.sh          # Verify WireGuard, diagnostics
└── run-all-tests.sh            # Full test suite
```

Tests verify:
- Package installation
- Service enablement
- Configuration correctness
- Idempotency (run twice, same result)

---

## Maintenance

### Regular Updates
```bash
# Users update their system regularly
sudo apt update && sudo apt upgrade

# Re-run setup if adding modules
sudo ./setup.sh

# Update configs in repo
git pull
```

### Backwards Compatibility
- All changes idempotent
- Old configs work with new code
- Graceful degradation for missing features

### Version Control
- Single source of truth in git
- Easy rollback
- Track all changes
- Collaborate via PR

---

## Dotfiles Management with Chezmoi

### Overview

The repository utilizes **Chezmoi** as its robust, industry-standard configuration file manager:

- **What**: Maps configurations securely to the target system.
- **Why**: Supports templating, conditionals, and secret management natively.
- **How**: The `home/` directory acts as the source state.

### Files Managed by Chezmoi

```
home/
├── dot_bashrc          → ~/.bashrc
├── dot_zshrc           → ~/.zshrc
├── dot_gitconfig       → ~/.gitconfig
└── dot_config/
    ├── i3/config       → ~/.config/i3/config
    └── sway/config     → ~/.config/sway/config
```

### Workflow: Edit and Deploy

1. Make changes immediately to the `home/` directory mappings in your repository.
2. Run `chezmoi --source . apply` to sync changes.
3. Commit and push directly to git!

---

## Future Enhancements

- [ ] Ansible playbooks for remote deployment
- [ ] Container image with pre-configured environment
- [ ] Automated CI/CD testing
- [ ] Multi-user workspace setup
- [ ] Backup/restore functionality
- [ ] GUI configuration tool
- [ ] Dotfiles manager integration
- [ ] Cloud-init support for VMs

