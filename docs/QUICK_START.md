# Quick Start Guide

## Prerequisites

- Debian 12 or 13, amd64 (a netinstall/minimal install is fine)
- Root access — run as `root` directly if `sudo` isn't installed yet (a minimal
  netinstall has no `sudo` when a root password was set during installation)
- Internet connection (the primary interface should already be up)
- 10GB+ free disk space
- Modern CPU (Intel or AMD, amd64)
- The **non-free-firmware** apt component enabled (the Debian 12+ installer
  enables it by default) — needed for firmware and CPU microcode. To check/add:
  ```bash
  grep -q non-free-firmware /etc/apt/sources.list || \
    sudo sed -i 's/ main$/ main non-free-firmware/' /etc/apt/sources.list && sudo apt-get update
  ```

> The setup bootstraps the rest itself: `00-base-system.sh` installs `sudo`,
> `git`, `curl`, `gnupg`, `unzip`, etc. before any module needs them.

### Do I need to add APT repositories manually first?

**No.** On a stock Debian 12/13 netinstall you do **not** add any repos by hand:

- **Third-party repos (Docker, HashiCorp/Terraform) are added by the script.**
  `02-development-tools.sh` writes the keyrings and `sources.list.d` entries for
  you, picking the correct codename automatically. If a repo doesn't yet publish
  your release (e.g. HashiCorp on trixie), it falls back on its own (distro
  `docker.io`; Terraform release binary) — no broken sources left behind.
- **`contrib` / `non-free` are NOT required.** Every distro package the setup
  installs lives in `main`. The *only* non-`main` packages are firmware
  (`firmware-*`) and CPU microcode, which come from **`non-free-firmware`** — and
  that component is enabled by default on a Debian 12+ netinstall (the check/add
  one-liner above covers the rare case where it isn't; the firmware step also
  just warns and continues if it's missing).
- **One assumption:** your `/etc/apt/sources.list` points at a network mirror
  (true whenever you picked a mirror during installation). A CD/USB-only install
  with no network mirror would need a normal Debian mirror line added first —
  this isn't special to the setup, it's needed for any `apt-get install`.

## Installation Steps

### 0. Bootstrap on a minimal netinstall (only if `git` is missing)

A bare netinstall may not include `git`. As root:
```bash
apt-get update && apt-get install -y git
```

### 1. Clone or download this repository

```bash
git clone https://github.com/yourusername/debian-setup.git
cd debian-setup
```

Or download the latest release:
```bash
wget https://github.com/yourusername/debian-setup/archive/refs/heads/main.zip
unzip main.zip
cd debian-setup-main
```

### 2. Make scripts executable

```bash
chmod +x setup.sh
chmod +x scripts/*.sh
```

### 3. Run the setup

> No `sudo` yet? Run as root instead: `su -` then `./setup.sh`.

**Full installation** (all components):
```bash
sudo ./setup.sh
# Choose "F" for Full installation
```

**Minimal installation** (base system only):
```bash
sudo ./setup.sh
# Choose "M" for Minimal installation
```

**Custom selection**:
```bash
sudo ./setup.sh
# Choose "C" for Custom
# Then select which modules to install
```

### 4. Installation takes approximately:
- **Minimal**: 10-15 minutes
- **Full**: 20-30 minutes (modules run sequentially; time is dominated by downloads)

---

## Which scripts run automatically vs. manually?

`sudo ./setup.sh` orchestrates the numbered modules for you — you do **not** run
`scripts/00`…`08` by hand. A few things are intentionally manual:

| Script | When | Notes |
|--------|------|-------|
| `scripts/00`–`05`, `07`, `08` | automatic | run by `setup.sh` (per the mode you pick) |
| `scripts/06-dotfiles.sh` | automatic **as your user** | `setup.sh` runs it as `$SUDO_USER` so symlinks land in *your* home. If you ran the setup as root directly (no sudo), run it yourself: `bash scripts/06-dotfiles.sh` |
| `scripts/update-binaries.sh` | **manual / periodic** | not part of the default run — updates kubectl/helm/k9s/kind/ActivityWatch. Run with `sudo` occasionally, or add to cron |
| `~/.config/i3/setup-monitors.sh` | **manual** | multi-monitor setup; also bound to `Super+Shift+N` (auto) / `Super+Shift+M` (interactive) |
| `power-profile` | **manual** | installed to `/usr/local/bin`; switch profiles on demand (or `Super+Shift+P`) |

> **Important:** always run `setup.sh` with `sudo` (not as root via `su`). With
> `sudo`, the dotfiles step is applied to your real user automatically; run as
> bare root, dotfiles would target `/root`, so you'd have to run
> `bash scripts/06-dotfiles.sh` as yourself afterward.

Manual one-time steps after the run (not scripts): re-login so new group
membership (docker/libvirt/video/kvm) takes effect; add your SSH public key to
GitHub; optionally `betterlockscreen -u ~/Pictures/wallpaper.png` to set the lock
wallpaper.

---

## Post-Installation Configuration

### Create a Regular User

```bash
sudo adduser yourusername
# Follow prompts

# Add to sudo group
sudo usermod -aG sudo yourusername

# Add to docker group (if Docker installed)
sudo usermod -aG docker yourusername

# Switch to new user
su - yourusername
```

### Setup Shell

```bash
# Set default shell to Zsh
chsh -s /bin/zsh

# Or use Bash
chsh -s /bin/bash
```

### Configure Git Identity

The `.gitconfig` is automatically symlinked by dotbot (includes delta, histogram diff, etc.).
You only need to set your personal name and email:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Generate SSH Keys

```bash
# Create Ed25519 key (modern, secure)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to SSH agent
ssh-add ~/.ssh/id_ed25519

# Display public key for GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
```

---

## Dotfiles Setup (Automatic)

The `06-dotfiles.sh` script (or `setup.sh` full install) runs dotbot which **automatically**:

- Creates all `~/.config/` subdirectories
- Symlinks all config files from this repo to your home directory
- Backs up any existing configs with timestamps
- Makes shell scripts executable
- Creates `~/.xinitrc` to start i3 via `startx`
- Warms the betterlockscreen blur cache (if a wallpaper is found)

**To apply dotfiles manually:**
```bash
# As your regular user (not root)
cd /path/to/debian-setup
bash scripts/06-dotfiles.sh
```

**Configs managed automatically (no manual copying needed):**

| Symlink | Source |
|---------|--------|
| `~/.bashrc` | `config/shell/.bashrc` |
| `~/.zshrc` | `config/shell/.zshrc` |
| `~/.gitconfig` | `config/shell/.gitconfig` |
| `~/.xinitrc` | `config/shell/.xinitrc` |
| `~/.config/i3/config` | `config/i3/config` |
| `~/.config/kitty/kitty.conf` | `config/kitty/kitty.conf` |
| `~/.config/polybar/config.ini` | `config/polybar/config.ini` |
| `~/.config/polybar/launch.sh` | `config/polybar/launch.sh` |
| `~/.config/dunst/dunstrc` | `config/dunst/dunstrc` |
| `~/.config/btop/btop.conf` | `config/btop/btop.conf` |
| `~/.config/lazygit/config.yml` | `config/lazygit/config.yml` |
| `~/.config/atuin/config.toml` | `config/atuin/config.toml` |
| `~/.config/starship.toml` | `config/starship.toml` |
| `~/.config/betterlockscreen/betterlockscreenrc` | `config/betterlockscreen/betterlockscreenrc` |

### After Dotfiles Are Applied

```bash
# Reload shell configuration
source ~/.bashrc    # Bash
source ~/.zshrc     # Zsh

# Start the desktop (first time, or from a TTY)
startx

# If i3 is already running, reload config
i3-msg restart

# Cache the lock screen wallpaper (run once, or after changing wallpaper)
betterlockscreen -u ~/Pictures/wallpaper.png
```

---

## Starting the Desktop

```bash
# Start from TTY (uses ~/.xinitrc → exec i3, created automatically by dotfiles)
startx

# Or install a display manager for a graphical login screen
sudo apt-get install lightdm
# Then reboot and select i3 at login
```

---

## First Login Walkthrough

### i3 Window Manager Keybindings

**Default modifier key: Super (Windows key)**

| Keybinding | Action |
|------------|--------|
| `Super+Enter` | Open Kitty terminal |
| `Super+d` | Launch application (rofi) |
| `Super+1-0` | Switch workspace |
| `Super+Shift+1-0` | Move window to workspace |
| `Super+h/j/k/l` | Move focus (vim keys) |
| `Super+Shift+h/j/k/l` | Move window |
| `Super+f` | Fullscreen mode |
| `Super+v` | Vertical split |
| `Super+b` | Horizontal split |
| `Super+Shift+q` | Close window |
| `Super+Shift+e` | Exit i3 |
| `Super+Shift+x` | Lock screen (betterlockscreen — blurred wallpaper + clock) |
| `Super+G` | Open lazygit (visual Git TUI) |
| `Super+Shift+v` | Open copyq clipboard history |
| `Print` | flameshot GUI screenshot (drag to select region) |
| `Super+Print` | Capture full screen to clipboard |
| `Super+Shift+Print` | Save full screenshot to ~/Pictures/screenshots |
| `Super+Shift+m` | Multi-monitor interactive setup |
| `Super+Ctrl+←/→` | Focus monitor left/right |
| `CTRL-R` | atuin history TUI (shows exit code, duration, directory) |

### Verify New Tools

```bash
# Shell prompt (should show git/lang info with icons)
starship --version

# Modern ls (with icons and git status)
eza -la --icons --git

# Syntax-highlighted cat
bat ~/.bashrc

# System monitor (all-in-one: CPU, memory, network, processes)
btop

# Git TUI (open in any git repo)
lazygit

# History search (CTRL-R opens TUI)
atuin stats

# Node version manager (replaces nvm)
fnm list

# Fast Python package manager (replaces pip)
uv --version
```

---

## Development Environment Quick Start

### Docker Example

```bash
# Pull an image
docker pull ubuntu:latest

# Run a container
docker run -it ubuntu /bin/bash

# If permission denied, ensure user is in docker group
sudo usermod -aG docker $USER
# Then log out and back in
```

### Kubernetes Example

```bash
kubectl version --client
helm version
kind version

# Create a test cluster
kind create cluster --name test
kind delete cluster --name test

# Use k9s for a visual cluster UI
k9s
```

### Python Development

```bash
# uv is pre-configured (10-100x faster than pip)
uv pip install ipython black ruff pytest

# Create a virtual environment
uv venv .venv && source .venv/bin/activate

# Install from requirements
uv pip install -r requirements.txt
```

### Node.js Development

```bash
# fnm is pre-configured (replaces nvm, 10x faster shell startup)
fnm install --lts        # Install latest LTS
fnm use --lts            # Use it
fnm list                 # List installed versions

# .nvmrc files are supported automatically
echo "20" > .nvmrc
fnm use                  # Reads .nvmrc

npm install -g yarn eslint prettier
```

### Go Development

```bash
# Go is installed and GOPATH is configured
go version
go env GOPATH

# Create a module
mkdir myapp && cd myapp
go mod init github.com/user/myapp
```

### SSH Example

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add your key
ssh-add ~/.ssh/id_ed25519

# Test SSH connection (after adding key to server)
ssh user@host.com
```

---

## Running Setup Multiple Times

The setup scripts are **fully idempotent**. You can safely:

1. **Run again to install missing components**:
   ```bash
   sudo ./setup.sh
   ```

2. **Re-apply dotfiles** (e.g. after pulling new config changes):
   ```bash
   bash scripts/06-dotfiles.sh
   ```

3. **Update system packages**:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

4. **Update dev tool binaries** (kubectl, helm, k9s, ActivityWatch):
   ```bash
   bash scripts/update-binaries.sh
   ```

---

## Next Steps

### Customize Your Workspace
- **Terminal**: Edit `config/kitty/kitty.conf` for font/colors (changes apply immediately via symlink)
- **Shell prompt**: Edit `config/starship.toml` to add/remove modules
- **Status bar**: Edit `config/polybar/config.ini` for modules and layout
- **i3 bindings**: Edit `config/i3/config` for custom keybindings

### Lock Screen Wallpaper
```bash
# Set any image as your blurred lock screen wallpaper
betterlockscreen -u ~/Pictures/my-wallpaper.jpg
# Then Super+Shift+X locks instantly with the blurred version
```

### System Administration
- Monitor system: `btop` (CPU, memory, network, processes — all in one)
- Review firewall: `sudo ufw status verbose`
- Check fail2ban: `sudo fail2ban-client status`
- Monitor power: `sudo powertop`
- Check thermal: `watch -n1 'sensors'`

### Productivity Tips
- **Terminal multiplexer**: `tmux` (see tmux cheatsheet)
- **Editor**: `nvim` (configure in `~/.config/nvim/`)
- **Git TUI**: `lazygit` (Super+G) — visual staging, rebase, cherry-pick
- **Clipboard history**: `Super+Shift+v` — copyq shows all recent clipboard entries
- **Shell history**: `CTRL-R` — atuin TUI with exit code, duration, and directory context

---

## Troubleshooting

### Docker Permission Denied

```bash
# Solution: Add user to docker group
sudo usermod -aG docker $USER
# Then log out and back in
```

### i3 Won't Start

```bash
# Check ~/.xinitrc exists (created automatically by dotfiles)
ls -la ~/.xinitrc
cat ~/.xinitrc   # Should contain: exec i3

# Check X11 logs
cat ~/.local/share/xorg/Xorg.0.log | tail -20

# Verify i3 is installed
which i3
```

### Polybar Not Appearing

```bash
# Test polybar manually
~/.config/polybar/launch.sh

# Check for errors
polybar main 2>&1 | head -20

# Reload i3 config
i3-msg restart
```

### betterlockscreen Not Working

```bash
# Cache a wallpaper first (required on first use)
betterlockscreen -u ~/Pictures/wallpaper.png

# Test lock manually
betterlockscreen -l blur

# Check if i3lock is available (dependency)
which i3lock
```

### Shell Config Not Loading (missing icons, no prompt)

```bash
# Check symlinks are correct
ls -la ~/.bashrc ~/.zshrc

# Re-run dotfiles
cd /path/to/debian-setup
bash scripts/06-dotfiles.sh

# Reload shell
exec $SHELL

# Verify Starship is installed
which starship
```

### SSH Key Permission Issues

```bash
# SSH keys should have restricted permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### TLP Battery Thresholds Not Working

```bash
# Some laptops (ThinkPad, System76) require special config
# Edit /etc/tlp.d/debian-setup.conf and check:
START_CHARGE_THRESH_BAT0=20
STOP_CHARGE_THRESH_BAT0=80

# Not all laptops support this - check your model's docs
```

### VPN (WireGuard) Configuration

```bash
# Generate keys
wg genkey | tee /tmp/privatekey | wg pubkey > /tmp/publickey

# Use keys in WireGuard config (~/.config/wireguard/wg0.conf)
# Then activate
sudo wg-quick up wg0
```

---

## Support & Documentation

- **Main documentation**: See `README.md`
- **Component rationale**: See `docs/SELECTIONS.md`
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md`
- **Architecture**: See `ARCHITECTURE.md`
- **Logs from setup**: Check `setup-YYYYMMDD-HHMMSS.log`

---

## Uninstalling Components

To remove a component:

```bash
# Remove i3 desktop
sudo apt remove i3 kitty polybar rofi

# Remove Docker
sudo apt remove docker-ce docker-ce-cli containerd.io

# Remove development tools
sudo apt remove golang-go nodejs npm

# Remove modern CLI tools
sudo apt remove eza bat git-delta btop
```

To clean up all dotfile symlinks:
```bash
# Remove dotfile symlinks (backups created by dotbot are unaffected)
for link in ~/.bashrc ~/.zshrc ~/.gitconfig ~/.xinitrc \
  ~/.config/i3/config ~/.config/kitty/kitty.conf \
  ~/.config/polybar/config.ini ~/.config/starship.toml; do
  [ -L "$link" ] && rm "$link"
done
```

---

## Providing Feedback

Found issues or have suggestions?

1. Check existing issues: https://github.com/yourusername/debian-setup/issues
2. Create a new issue with:
   - Your Debian version (`cat /etc/os-release`)
   - Hardware info (`lscpu`)
   - Exact error message
   - Steps to reproduce
