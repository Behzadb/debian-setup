# Debian Setup - Repository Structure Documentation

## Project Layout

```
debian-setup/
│
├── README.md                     # Main project documentation
├── ARCHITECTURE.md               # This file - system design & structure
├── DOCUMENTATION.md              # Documentation guide
├── setup.sh                      # Entry point (sequential orchestrator)
├── setup-helpers.sh              # Utility functions library
├── install.conf.yaml             # Dotbot configuration (19 symlinks managed)
│
├── scripts/                      # Modular installation scripts (numbered order)
│   ├── 00-base-system.sh        # [1] Core system setup (kernel, firmware, build tools)
│   ├── 01-window-manager.sh     # [2] Desktop: i3, Kitty, Polybar, flameshot, copyq, btop
│   ├── 02-development-tools.sh  # [3] Dev tools: Docker, K8s, eza/bat/delta/lazygit, Starship, atuin, fnm, uv
│   ├── 03-security.sh           # [4] Security hardening (UFW, fail2ban, SSH)
│   ├── 04-power-management.sh   # [5] Power & thermal management (TLP, thermald)
│   ├── 05-networking.sh         # [6] Network tools & VPN (WireGuard, mtr, nmap)
│   ├── 06-dotfiles.sh           # [7] Dotfiles manager (dotbot symlinks)
│   ├── 07-post-installation.sh  # [8] Post-setup (SSH keys, user groups, finalization)
│   ├── 08-generate-docs.sh      # [9] Generates System-Reference.md from the live system
│   └── update-binaries.sh        # Binary update manager (kubectl, helm, k9s, ActivityWatch)
│
├── config/                       # Configuration templates (all symlinked via dotbot)
│   ├── i3/                      # i3 window manager (Catppuccin Mocha theme)
│   │   ├── config               # Main i3 config (keybindings, workspaces, Catppuccin colors)
│   │   └── setup-monitors.sh    # Monitor detection & profile manager (xrandr)
│   ├── nvim/                    # Neovim (reuses ~/.vimrc + ~/.vim plugins)
│   │   └── init.vim             # Sources ~/.vimrc so nvim == the configured vim
│   ├── kitty/                   # Kitty terminal (GPU-accelerated)
│   │   └── kitty.conf           # FiraCode Nerd Font, Catppuccin Mocha, ligatures
│   ├── polybar/                 # Polybar status bar (replaces i3status)
│   │   ├── config.ini           # Modules: i3 workspaces, CPU/temp/mem, battery, network, audio
│   │   └── launch.sh            # Multi-monitor launch script
│   ├── dunst/                   # Notification daemon
│   │   └── dunstrc              # Catppuccin Mocha, 8px corner radius, Nerd Font icons
│   ├── btop/                    # System monitor (replaces htop)
│   │   └── btop.conf            # Catppuccin theme, vim keys, all panels
│   ├── lazygit/                 # Git TUI
│   │   └── config.yml           # Catppuccin theme, delta integration, vim keys
│   ├── atuin/                   # Shell history (replaces CTRL-R)
│   │   └── config.toml          # Local SQLite, fuzzy search, secret filtering
│   ├── starship.toml            # Shell prompt (Catppuccin Mocha palette)
│   └── shell/                   # Shell & Git configs
│       ├── .bashrc              # Bash: eza/bat aliases, starship, atuin, fnm
│       ├── .zshrc               # Zsh: starship, atuin, fnm, eza/bat aliases
│       ├── .gitconfig           # Git: delta pager, histogram diff, identity via ~/.gitconfig.local
│       └── .xinitrc             # X11 startup: xset, xrdb merge, exec i3
│
├── dotbot/                       # Dotbot submodule (dotfiles manager)
│   └── [dotbot files]
│
├── docs/                         # Documentation directory
│   ├── QUICK_START.md           # Getting started guide with examples
│   ├── SELECTIONS.md            # Component rationale & comparison (updated for modern stack)
│   ├── TROUBLESHOOTING.md       # 40+ common issues & solutions
│   ├── DEBIAN13_COMPATIBILITY.md# Debian 13 verification & compatibility report
│   └── DOTBOT_GUIDE.md          # Dotfiles management guide
│
└── [Future: tests/, CI/workflows/] # Test suite & GitHub Actions (coming soon)
```

## File Purposes

### Root Level Files

| File | Purpose |
|------|---------|
| `setup.sh` | Main entry point - orchestrates all modules |
| `setup-helpers.sh` | Utility functions - logging, checks, helpers |
| `.env.example` | Reference only — points to where config actually lives (NOT loaded by any script) |
| `.gitignore` | Git ignore patterns - excludes logs, backups |
| `README.md` | Project overview, quick start, features |

### Scripts Directory (`scripts/`)

Each script is **independently executable** and **fully idempotent**:

| Script | Purpose | Key Components |
|--------|---------|-----------------|
| `00-base-system.sh` | Kernel, firmware, build tools | Linux kernel (generic), `firmware-linux*` + `firmware-misc-nonfree` (webcam/wifi/bt), CPU microcode, gcc, make, git, curl |
| `01-window-manager.sh` | Desktop environment | i3, picom, rofi, lightdm, **Kitty**, **Polybar**, audio (PipeWire + pavucontrol), webcam (V4L2/v4l-utils), Bluetooth (bluez/blueman), **flameshot**, **copyq**, **btop**, FiraCode Nerd Font |
| `02-development-tools.sh` | Dev stack & tools | Languages (Go, Python+**uv**, Node.js+**fnm**), Docker, K8s, KVM/Vagrant, **eza**, **bat**, **delta**, **lazygit**, **Starship**, **atuin** |
| `03-security.sh` | Security hardening | UFW firewall, fail2ban, SSH hardening, AIDE |
| `04-power-management.sh` | Power & thermal | TLP (EPP + ACPI platform-profile, tuned for ThinkPad T14), thermald, powertop, `power-profile` switcher |
| `05-networking.sh` | Network tools | WireGuard, mtr, tcpdump, nmap, dig, iperf3 |
| `06-dotfiles.sh` | Dotfiles manager | Dotbot symlink setup, 19 managed configs |
| `07-post-installation.sh` | Post-setup tasks | SSH keys, user groups (sudo/docker/libvirt/wireshark/**video**/**audio**/plugdev), shell selection |
| `08-generate-docs.sh` | Documentation | Generates `System-Reference.md` from the live system (tools, network, keybindings) |
| `update-binaries.sh` | Binary updates | GitHub API for kubectl, helm, k9s, ActivityWatch version checking |

### Config Directory (`config/`)

Pre-configured files symlinked via dotbot to user home. All follow Catppuccin Mocha theme:

```
config/
├── i3/
│   ├── config                 # i3: Catppuccin Mocha borders, Kitty terminal, Polybar exec
│   └── setup-monitors.sh      # Monitor auto-detect & xrandr profile manager
│
├── nvim/
│   └── init.vim               # Neovim: reuses ~/.vimrc + ~/.vim plugins (vim-plug)
│
├── kitty/
│   └── kitty.conf             # GPU terminal: FiraCode Nerd Font, Catppuccin Mocha, ligatures
│
├── polybar/
│   ├── config.ini             # Modules: i3 workspaces, CPU/temp/mem/battery/network/audio
│   └── launch.sh              # Multi-monitor polybar launcher
│
├── dunst/
│   └── dunstrc                # Notifications: Catppuccin Mocha, corner_radius=8, Nerd Font
│
├── btop/
│   └── btop.conf              # System monitor: Catppuccin theme, vim keys, all panels
│
├── lazygit/
│   └── config.yml             # Git TUI: Catppuccin, delta integration, vim navigation
│
├── atuin/
│   └── config.toml            # History: local SQLite, fuzzy search, secret filtering
│
├── rofi/
│   ├── config.rasi            # Launcher: drun mode, @import the Catppuccin theme
│   └── catppuccin-mocha.rasi  # Catppuccin Mocha Rofi theme
│
├── betterlockscreen/
│   └── betterlockscreenrc     # Lock screen: blur + Catppuccin ring/fonts
│
├── power/
│   ├── power-profile.sh       # Profile switcher (installed to /usr/local/bin, NOT symlinked)
│   └── radio-toggle.sh        # WiFi/WWAN/BT/Ethernet toggle (installed to /usr/local/bin, NOT symlinked)
│
├── starship.toml              # Prompt: Catppuccin Mocha palette, async git/lang/k8s info
│
└── shell/
    ├── .bashrc                # Bash: PATH, fzf→atuin order, eza/bat aliases, starship/atuin/fnm
    ├── .zshrc                 # Zsh: PATH, fzf→atuin order, eza/bat aliases, starship/atuin/fnm
    ├── .gitconfig             # Git: delta pager, histogram diff, identity via ~/.gitconfig.local
    └── .xinitrc               # X11 startup: xset keyboard rate, xrdb merge, exec i3
```

### Docs Directory (`docs/`)

Comprehensive documentation for users:

| Document | Content |
|----------|---------|
| `QUICK_START.md` | Step-by-step setup guide, post-install configuration, examples |
| `SELECTIONS.md` | Component rationale, pros/cons, alternative tool comparisons |
| `TROUBLESHOOTING.md` | 40+ common issues, solutions, debugging tips, error messages |
| `DEBIAN13_COMPATIBILITY.md` | Debian 13 verification report, compatibility details |
| `DOTBOT_GUIDE.md` | Dotfiles management with dotbot, workflows, profile switching |
| `ARCHITECTURE.md` | Deep dive into system design, extensibility, customization (this file) |
| `DOCUMENTATION.md` | Navigation guide for all documentation files |

---

## Execution Flow

### Installation Flow (Sequential & Lock-Safe)

1. **Pre-flight Checks**
   - Verify root/sudo permission
   - Check all scripts exist
   - Test internet connectivity
   - Verify disk space

2. **User Chooses Mode**
   - **Full** (F) - All modules (01-05), then optionally dotfiles
   - **Minimal** (M) - Base system only
   - **Custom** (C) - Pick and choose modules
   - **Development** (D) - Base + dev tools + dotfiles

3. **Execute Modules Sequentially**

   Modules always run one after another. This is deliberate: running multiple
   `apt-get` operations at once would contend for the dpkg/apt lock and fail.
   `setup.sh` calls `wait_for_apt_lock` before each module.
   ```
   00-base-system.sh   (required, runs first)
   └─> 01-window-manager.sh
   └─> 02-development-tools.sh
   └─> 03-security.sh
   └─> 04-power-management.sh
   └─> 05-networking.sh
   └─> 06-dotfiles.sh        (prompted in Full mode)
   ```

4. **Post-Installation Steps** (always run, after the selected modules)
   - `07-post-installation.sh` - user account, SSH keys, Git, Vim plugins
   - System cleanup (`apt-get upgrade`/`autoremove`/`autoclean`)
   - `08-generate-docs.sh` - generate `System-Reference.md`

### Running Individual Scripts

Each module can also be run on its own (they source `setup-helpers.sh` and
re-check prerequisites):
```bash
sudo bash scripts/00-base-system.sh
sudo bash scripts/01-window-manager.sh
sudo bash scripts/02-development-tools.sh
sudo bash scripts/03-security.sh
sudo bash scripts/04-power-management.sh
sudo bash scripts/05-networking.sh
bash scripts/06-dotfiles.sh           # run as your normal user, not root
sudo bash scripts/07-post-installation.sh
sudo bash scripts/08-generate-docs.sh
sudo bash scripts/update-binaries.sh  # optional, run later
```

### Dependency Order & Prerequisites

The order is not arbitrary — later steps consume what earlier steps install:

- **`00` bootstraps everything.** It installs the tools every other module relies
  on before they are used: `curl`, `wget`, `git`, `gnupg`, `ca-certificates`,
  `lsb-release`, `unzip`, `python3`/`python3-yaml`, plus `sudo`, `psmisc`
  (`fuser` for the apt-lock guard) and `procps`. In every mode `setup.sh` runs
  `00` first. Run it first for standalone use too.
- **`02` adds third-party APT repos** (Docker, HashiCorp) and is the main
  ordering-sensitive step. It now: (a) re-ensures its repo prerequisites so it is
  self-sufficient, (b) resolves the Debian codename via `lsb_release` with an
  `/etc/os-release` fallback and skips the repo rather than writing a malformed
  line if unknown, and (c) tolerates a failing repo refresh — falling back to
  `docker.io` for Docker and to the release **binary** for Terraform (so a
  codename the HashiCorp repo hasn't published yet, e.g. trixie, can't abort the
  run or leave a broken `sources.list.d` entry).
- **`04` installs `power-profile` before `06`** symlinks the i3/Polybar configs
  that reference it (correct in Full/Custom order).
- **`06` (dotfiles) only creates symlinks** — it needs `git`+`python3-yaml`
  (from `00`); configs that point at tools from `01`/`02` are harmless symlinks
  if those modules were skipped (all shell configs guard with `command -v`).
- **`07` runs last** and needs `vim`+`git`+`curl` (from `00`); group adds are
  guarded by `getent group`, so missing groups (e.g. `docker` in Minimal) are
  skipped, not errors.
- **No intra-batch apt conflicts.** Mutually exclusive packages are never in the
  same `ensure_pkgs` call (e.g. PipeWire vs PulseAudio are separate branches);
  see the coexistence table in `docs/DEBIAN13_COMPATIBILITY.md`.

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

### 1. Sequential, Lock-Safe Installation (setup.sh)

**What**: Runs installation modules one at a time, guarding the apt/dpkg lock
between each so package operations never collide.

**How**:
```bash
run_script() {
    wait_for_apt_lock      # block until any other apt/dpkg process finishes
    bash "$SCRIPTS_PATH/$script" 2>&1 | tee -a "$LOG_FILE"
}
```

**Why not parallel**: Only one process may hold the dpkg lock
(`/var/lib/dpkg/lock-frontend`) at a time. Running modules concurrently would
make `apt-get` fail with "Could not get lock". Typical full run is 15-25 min,
dominated by downloads rather than CPU.

**Files Involved**:
- [setup.sh](setup.sh) - `run_script()` function
- [setup-helpers.sh](setup-helpers.sh) - `wait_for_apt_lock()`, resilient `ensure_pkgs()`

---

### 2. Polybar Status Bar (replaces i3status)

**What**: Beautiful, icon-capable, click-actionable status bar with runtime hardware detection.

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
- `temperature` - CPU temp with icons; graceful `──°C` fallback when no sensor (VM/desktop)
- `memory` - RAM usage
- `battery` - Charging animation; shows plug-icon fallback on desktops with no BAT0
- `network-wireless` / `network-wired` - two modules (polybar has no `any`
  interface-type); only the connected one renders, so WiFi shows on the road and
  Ethernet when docked
- `pulseaudio` - Volume via PipeWire-pulse compat layer (or legacy PulseAudio); right-click → pavucontrol
- `date` - Date and time
- `tray` - dedicated system-tray module (polybar 3.7+; the old bar-level `tray-*`
  keys are deprecated)

**Multi-monitor**: `launch.sh` starts one bar per connected output and waits for
old instances to fully exit before relaunching (a fixed sleep races the X
systray release → "Systray selection already managed"). If an instance ignores
the polite `SIGTERM` (a hung `custom/script` module can cause this), it is
**SIGKILL**ed after a grace period — otherwise the respawn races a not-yet-dead
bar and leaves duplicated/stacked bars that an i3 reload won't clear. Because only one polybar
may own the system tray, the launcher includes the `tray` module **only on the
primary monitor** via `TRAY_MODULE=tray` (empty elsewhere), so the tray icons
appear exactly once instead of the secondary bars failing to claim it. The
launcher is **race-safe** (`flock`): i3's `exec_always`, the Super+Shift+N
keybind and the hotplug service can all fire it at once, so without the lock they
interleave kill/spawn and leave **duplicate bars** — flock serializes them so the
last run produces exactly one bar per output. `setup-monitors.sh` calls it after
every layout change so the bars always match the current monitors.

**Files Involved**:
- [config/polybar/config.ini](config/polybar/config.ini) - bar + modules (`modules-right = … ${env:TRAY_MODULE:}`, `[module/tray]`)
- [config/polybar/launch.sh](config/polybar/launch.sh) - per-monitor launcher; kill-and-wait; tray on the primary output
- [config/i3/config](config/i3/config) - `exec_always ~/.config/polybar/launch.sh`

**Note**: i3status is not configured by this setup — Polybar is the only status
bar. (The `i3status` package may still be pulled in by the `i3` meta-package, but
nothing here generates or links an i3status config.)

---

### 3. Multi-Monitor Support (setup-monitors.sh)

**What**: Detect monitors, create configurations, save/load profiles for home/office.

**Features**:
- **Auto-detect**: Lists all connected/disconnected monitors
- **Auto-configure (optimal)**: each monitor at its **native resolution** (mixed
  sizes are fine), laid out left→right and **vertically centered** so the cursor
  crosses cleanly even when heights differ (no dead-zone); the **largest external
  is set primary** when docked (else the internal panel); disconnected outputs off.
- **HiDPI**: if the primary is clearly HiDPI (≈≥168 DPI, e.g. a 4K/QHD small
  panel) it sets a sane global `Xft.dpi` (144/192) so text isn't tiny — standard
  ~96 DPI monitors are left untouched. (X11 has one global DPI, so on mixed-DPI
  setups this scales to the primary; override in `~/.Xresources`.)
- **Interactive**: Menu for extend right/left/above/below, mirror (Super+Shift+M)
- **Profiles**: Save current layout as named profile (home, office)
- **Automatic hotplug**: a udev DRM rule (`95-monitor-hotplug.rules`) triggers a
  oneshot `monitor-hotplug.service` whenever a display is connected/disconnected.
  It finds the running i3 session's `DISPLAY`/`XAUTHORITY` from `/proc` and re-runs
  `setup-monitors.sh auto` as that user — so plugging in an external display just
  works, no keypress. **Super+Shift+N** still forces a re-detect manually.
- **Polybar follows the layout**: every `setup-monitors.sh` run relaunches
  Polybar so the bars are recreated on the current outputs (no stale bar on a
  removed monitor, a bar on a new one).

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
- Integrated with i3 keybindings: **Super+Shift+N** = auto, **Super+Shift+M** =
  interactive. Interactive prompts for input, so its keybinding opens a Kitty
  terminal (`kitty -e …`) rather than running headless.
- `detect_monitors` prints only bare output names to stdout (diagnostics go to
  stderr) so `monitors=($(detect_monitors))` is never polluted by banner text.

**Files Involved**:
- [config/i3/setup-monitors.sh](config/i3/setup-monitors.sh) - Main script (also relaunches Polybar)
- [config/i3/monitor-hotplug.sh](config/i3/monitor-hotplug.sh) - hotplug handler (installed to `/usr/local/bin/monitor-hotplug`)
- `/etc/systemd/system/monitor-hotplug.service` + `/etc/udev/rules.d/95-monitor-hotplug.rules` - installed by `01-window-manager.sh`
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
# Location: /opt/activitywatch  (binaries symlinked into /usr/local/bin)
```

**Launching** (no systemd unit is created — start it from your session):
```bash
# Binaries are on PATH via /usr/local/bin symlinks
aw-qt &        # tray app that supervises aw-server + watchers
# or run the server directly:
aw-server &
```
To autostart it under i3, add `exec --no-startup-id aw-qt` to `~/.config/i3/config`.

**Files Involved**:
- [scripts/02-development-tools.sh](scripts/02-development-tools.sh) - Section 14: Installation
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

### 7. Power Management & Profiles (ThinkPad T14 Gen3/Gen7)

**What**: A robust, vendor-neutral power setup for the ThinkPad T14 (both the
Intel and AMD variants of Gen3 and Gen7), plus an on-demand profile switcher.

**Why EPP + platform_profile instead of governors**: Modern T14s run
`intel_pstate` (Intel) or `amd_pstate` (AMD) in their default *active* mode,
which only expose the `powersave` and `performance` governors — **not**
`schedutil`/`ondemand`. So pacing is done with knobs that exist on both:
- **EPP** (Energy-Performance-Preference): `balance_performance` on AC,
  `power` on battery — the main battery lever, still allows turbo.
- **ACPI platform profile** (`/sys/firmware/acpi/platform_profile`): the
  ThinkPad firmware power envelope (`low-power` / `balanced` / `performance`),
  driven via TLP's `PLATFORM_PROFILE_ON_AC/BAT` (TLP ≥ 1.5, Debian 12+).
- Turbo off on battery; Intel HWP dynamic boost on AC.
- Native `thinkpad_acpi` charge thresholds (`START/STOP_CHARGE_THRESH_BAT0`).

**Automatic baseline (TLP)**: TLP applies the AC vs battery settings above on
every power-source change. Bluetooth is intentionally **not** disabled on
battery (so BT headset mics keep working unplugged), and USB autosuspend
excludes audio/bluetooth (so wired mics/webcams don't drop).

**Manual situational profiles (`power-profile`)**: a small, safe CLI installed
to `/usr/local/bin/power-profile` that overrides the baseline on demand:

```bash
power-profile performance   # platform=performance, EPP=performance,        turbo on
power-profile balanced      # platform=balanced,    EPP=balance_performance, turbo on
power-profile powersave     # platform=low-power,   EPP=power,               turbo off
power-profile auto          # re-apply TLP's AC/BAT defaults (tlp start)
power-profile status        # show platform profile / governor / EPP / turbo / battery
power-profile cycle         # powersave -> balanced -> performance -> ...
```

It only writes to sysfs nodes that exist and validates each value against what
the hardware advertises (`platform_profile_choices`,
`energy_performance_available_preferences`), so it never errors on unsupported
hardware — it simply skips. It does **not** fight TLP: TLP owns the automatic
AC/BAT baseline; the override lasts until the next power-source change (or
`power-profile auto`).

**Integration**:
- **i3**: `Super+Shift+P` opens a `power` mode (`p`/`b`/`s`/`a`), with a
  desktop notification on switch.
- **Polybar**: a `powerprofile` module shows the current ACPI profile (⚡) and
  **left-click cycles** it. It hides itself on machines without a platform
  profile (VMs/desktops).
- **sudo**: a tightly-scoped `/etc/sudoers.d/power-profile` lets the `sudo`
  group run only `/usr/local/bin/power-profile` without a password, so the
  keybindings/click work without a prompt (validated with `visudo -c`).

**Disabling radios you don't need (`radio-toggle` + TLP Radio Device Wizard)**:
two complementary layers turn off hardware that wastes battery when idle.
- **Automatic (TLP rdw)** — `/etc/tlp.d/debian-setup.conf` drops WiFi + cellular
  when you plug in Ethernet (restored on unplug), drops cellular when WiFi
  connects, and drops an idle cellular modem on battery. Bluetooth is left alone
  so headsets/mice keep working. Rules for a device that isn't present are silent
  no-ops, so the same config is safe on machines without a WWAN card.
- **Manual (`radio-toggle`)** — installed to `/usr/local/bin/radio-toggle`; it
  toggles WiFi / WWAN / Bluetooth (via `rfkill`) and Ethernet (via NetworkManager)
  on demand: `radio-toggle wwan off`, `radio-toggle status`, `radio-toggle all-off`.
  i3 binds **Super+Shift+O** to a `radio` mode (`w`/`m`/`b`/`e`/`o`), running via a
  scoped `/etc/sudoers.d/radio-toggle` NOPASSWD rule (validated with `visudo -c`).
  `status` works without root.

**Lid close / suspend / lock**: suspend on lid close is handled by
systemd-logind's default `HandleLidSwitch=suspend` (the setup does not override
logind). The screen locks *before* sleeping because i3 runs
`xss-lock --transfer-sleep-lock -- i3lock -n -c 1e1e2e` (plain i3lock; see
TODO.md for the i3lock-color/betterlockscreen upgrade), which holds
logind's sleep inhibitor until the locker is up and also locks after 10 min idle
(`xset s 600`). When docked (external monitor), logind's default
`HandleLidSwitchDocked=ignore` means lid-close does not suspend — by design.

**Files Involved**:
- [config/power/power-profile.sh](config/power/power-profile.sh) - the switcher (installed to `/usr/local/bin/power-profile`)
- [config/power/radio-toggle.sh](config/power/radio-toggle.sh) - WiFi/WWAN/Bluetooth/Ethernet toggle (installed to `/usr/local/bin/radio-toggle`)
- [scripts/04-power-management.sh](scripts/04-power-management.sh) - TLP config (incl. rdw rules), helper installs, sudoers rules
- [config/i3/config](config/i3/config) - `Super+Shift+P` power mode, `Super+Shift+O` radio mode
- [config/polybar/config.ini](config/polybar/config.ini) - `[module/powerprofile]`

**Battery life expectations (T14, ~52.5 Wh battery)** — rough, real-world ranges
with this config; **screen brightness and panel dominate**, so treat as ballpark:

| Workload | Draw | Gen3 (full) | Gen3 @ 80% cap | Gen7* (full) |
|----------|------|-------------|----------------|--------------|
| Light (web, editing, low brightness) | ~6 W | ~8–9 h | ~7 h | ~10–14 h |
| Mixed dev (editor, some build, WiFi) | ~10 W | ~5 h | ~4 h | ~6–8 h |
| Video call in Chromium (cam+mic+enc) | ~18 W | ~2.5–3 h | ~2.3 h | ~3–4 h |

\*Gen7 = newer, more efficient CPU; figures assume a similar/larger pack.

What this config already does for battery: EPP=`power`, turbo off, platform
profile `low-power`, PCIe ASPM `powersave`, WiFi power-save, runtime PM auto, USB
autosuspend (audio/BT excluded). That covers nearly all the TLP-level wins.

**Room for improvement (highest impact first):**
1. **Charge cap costs ~20% runtime.** `STOP_CHARGE_THRESH_BAT0=80` trades capacity
   for longevity. For maximum runtime per charge set it to `100` in
   `/etc/tlp.d/debian-setup.conf` then `sudo tlp start` (re-introduces normal
   battery wear). This is the single biggest "free" runtime knob.
2. **Screen brightness is the largest physical draw (~1–6 W).** Lower it, or add a
   dim-on-battery hook (`brightnessctl set 40%` from a TLP/udev battery hook).
3. **Suspend mode (handled).** s2idle ("Modern Standby") drains ~1–2%/h; S3
   "deep" is ~0.3%/h. The `suspend-deep-sleep.service` (installed by `04`)
   switches to **deep** at boot *only when the firmware advertises it*
   (`grep -qw deep /sys/power/mem_sleep`) — a safe no-op otherwise, and reversible
   with `systemctl disable --now suspend-deep-sleep.service`. It never edits the
   GRUB cmdline, so it can't force an unsupported state and break resume.
   - For **near-zero drain on long suspends**, opt into *suspend-then-hibernate*:
     it sleeps first, then hibernates to swap and powers off. Requires swap ≥ RAM
     and (usually) Secure Boot off, so it's left opt-in — set
     `HandleLidSwitch=suspend-then-hibernate` in `/etc/systemd/logind.conf` and
     tune `HibernateDelaySec` in `/etc/systemd/sleep.conf`.
4. **Marginal:** `PCIE_ASPM_ON_BAT=powersupersave` (small, usually safe). Avoid
   `powertop --auto-tune` as a permanent setting — it re-enables USB autosuspend
   for everything and can drop mic/webcam (TLP already does the safe subset).

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

## Dotfiles Management with Dotbot

### Overview

The repository includes **Dotbot** - a lightweight dotfiles manager that handles configuration file symlinks:

- **What**: Manages symlinks for shell configs, git config, i3 configuration
- **Why**: Version-controlled configurations that apply immediately and work on multiple machines
- **How**: YAML configuration file (`install.conf.yaml`) defines all symlinks

### Dotbot Configuration

File: `install.conf.yaml`

```yaml
configure:
  # Create symlinks for shell configs
  - link:
      ~/.bashrc: config/shell/.bashrc
      ~/.zshrc: config/shell/.zshrc
      ~/.gitconfig: config/shell/.gitconfig

  # Create directories for i3
  - create:
      - ~/.config/i3

  # Link i3 configs
  - link:
      ~/.config/i3/config: config/i3/config
      ~/.config/i3/setup-monitors.sh: config/i3/setup-monitors.sh

  # Backup existing files before symlinking
  - shell:
      - command: cp ~/.bashrc ~/.bashrc.backup.$(date +%s)
        description: Backup .bashrc if exists
```

### Files Managed by Dotbot

```
config/shell/
├── .bashrc          → ~/.bashrc
├── .zshrc           → ~/.zshrc
└── .gitconfig       → ~/.gitconfig

config/i3/
├── config           → ~/.config/i3/config
└── setup-monitors.sh → ~/.config/i3/setup-monitors.sh
```

### Benefits of This Approach

| Benefit | How It Works |
|---------|-------------|
| **Version Control** | All configs tracked in git |
| **Portability** | Same configs on all machines |
| **Immediate Effect** | Edit file → change applies instantly (symlinked) |
| **Idempotent** | Safe to run multiple times |
| **Backups** | Old configs backed up with timestamp before symlinking |
| **Easy Rollback** | Either use git or restore from backup |

### Workflow: Edit and Deploy

```bash
# 1. Edit config in repository (changes apply immediately via symlink)
cd /home/behzadbarabadi/project/debian-setup
vim config/shell/.bashrc
source ~/.bashrc  # Reload

# 2. Commit changes to git
git add config/shell/.bashrc
git commit -m "Add new bash alias"

# 3. Deploy to another machine
# On new machine:
cd debian-setup
./scripts/06-dotfiles.sh
# All configs automatically symlinked
```

### Installation

**Via Full Setup:**
```bash
sudo ./setup.sh
# Choose [F]ull, then select "Install Dotfiles Manager? (y/n):"
```

**Standalone:**
```bash
./scripts/06-dotfiles.sh
```

### Adding New Dotfiles

1. Copy file to `config/` directory
2. Update `install.conf.yaml` with new symlink
3. Re-run: `./scripts/06-dotfiles.sh`
4. Commit to git

### Advanced: Conditional Configs

For sensitive or machine-specific settings:

```bash
# In ~/.bashrc (symlinked to repository):
[ -f ~/.bashrc.local ] && source ~/.bashrc.local

# Create ~/.bashrc.local (not in repository):
export MACHINE_SPECIFIC_VAR="value"
```

Add `*.local` to `.gitignore` to keep secrets out of version control.

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

