# Quick Start Guide

## Prerequisites

- Debian netinstall (minimal installation)
- Root access or sudo privileges
- Internet connection
- 10GB+ disk space
- Modern CPU (Intel or AMD)

## Installation Steps

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
- **Full**: 30-45 minutes (depending on internet speed)

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

### Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Or copy the template config
cp debian-setup/config/shell/.gitconfig ~/.gitconfig
# Then edit with your details
```

### Generate SSH Keys

```bash
# Create Ed25519 key (modern, secure)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Or RSA (4096-bit for compatibility)
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"

# Add to SSH agent
ssh-add ~/.ssh/id_ed25519

# Display public key for GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
```

### Setup Shell Configuration

Copy provided shell configs:

```bash
# For Bash
cp debian-setup/config/shell/.bashrc ~/.bashrc
source ~/.bashrc

# For Zsh
cp debian-setup/config/shell/.zshrc ~/.zshrc
source ~/.zshrc
```

### Configure i3 Window Manager

```bash
# Create config directory
mkdir -p ~/.config/i3
mkdir -p ~/.config/i3status

# Copy configuration files
cp debian-setup/config/i3/config ~/.config/i3/config
cp debian-setup/config/i3/i3status.conf ~/.config/i3status/config

# Create X11 startup file
cat > ~/.xinitrc << 'EOF'
exec i3
EOF

chmod +x ~/.xinitrc
```

### Start X11 with i3

```bash
# Start from tty
startx

# Or install a display manager
sudo apt-get install lightdm

# Then restart and select i3 at login
```

### Verify Docker Installation

```bash
docker --version
docker run hello-world

# If permission denied, ensure user is in docker group
# (may need to log out and back in for group changes)
```

### Verify Kubernetes Tools

```bash
kubectl version --client
helm version
kind version

# Create a test cluster
kind create cluster --name test
kind delete cluster --name test
```

### Configure Docker for your user

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then test
docker ps
```

---

## First Login Walkthrough

### i3 Window Manager Basics

**Most Important Keybindings** (default uses Windows/Super key):

| Keybinding | Action |
|------------|--------|
| `Super+Enter` | Open terminal |
| `Super+d` | Launch application |
| `Super+1-0` | Switch workspace |
| `Super+Shift+1-0` | Move window to workspace |
| `Super+h/j/k/l` | Move focus (vim keys) |
| `Super+Shift+h/j/k/l` | Move window |
| `Super+f` | Fullscreen mode |
| `Super+v` | Vertical split |
| `Super+b` | Horizontal split |
| `Super+Shift+q` | Close window |
| `Super+Shift+e` | Exit i3 |
| `Super+Shift+l` | Lock screen |

### Development Environment Quick Start

#### Docker Example

```bash
# Pull an image
docker pull ubuntu:latest

# Run a container
docker run -it ubuntu /bin/bash

# List containers
docker ps -a

# View logs
docker logs <container-id>
```

#### Kubernetes Example

```bash
# Create a local cluster
kind create cluster --name dev

# Deploy an example application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# View pods
kubectl get pods

# View services
kubectl get svc

# Check logs
kubectl logs -f deployment/nginx

# Clean up
kind delete cluster --name dev
```

#### SSH Example

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
   # Choose which modules to add
   ```

2. **Update system packages**:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

3. **Re-run specific modules** (if you modified configurations):
   ```bash
   sudo bash scripts/04-power-management.sh
   ```

The scripts will:
- Skip already-installed packages
- Not reinstall software
- Preserve your configurations
- Update sysctl/service settings safely

---

## Next Steps

### Learn i3
- Press `Super+?` for help in i3 (if configured)
- Read i3 documentation: https://i3wm.org/docs/

### Development Setup
1. **Python**: `pip install --user ipython black flake8 pytest`
2. **Node.js**: `npm install -g yarn eslint prettier`
3. **Go**: Set `GOPATH` and use `go get` for packages

### System Administration
- Monitor power: `sudo powertop`
- Check thermal: `watch -n1 'sensors'`
- Review firewall: `sudo ufw status verbose`
- Check fail2ban: `sudo fail2ban-client status`

### Productivity Tools
- Terminal multiplexer: `tmux` (see tmux cheatsheet)
- Fuzzy finder: `fzf` (CTRL-T for files, CTRL-R for history)
- Terminal text editor: `nvim` (configure in `~/.config/nvim/`)

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
# Check X11 configuration
startx -- -verbose

# Check X11 logs
cat ~/.local/share/xorg/Xvfb.log

# Or try simpler window manager first
exec openbox
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

- **Main documentation**: See `docs/SELECTIONS.md`
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md`
- **Logs from setup**: Check `setup-YYYYMMDD-HHMMSS.log`

---

## Uninstalling Components

To remove a component, use apt:

```bash
# Remove i3
sudo apt remove i3 i3status rofi

# Remove Docker
sudo apt remove docker-ce docker-ce-cli containerd.io

# Remove specific development tool
sudo apt remove golang-go nodejs npm
```

To clean up all configuration:
```bash
# Remove shell configs
rm ~/.bashrc ~/.zshrc ~/.gitconfig

# Remove i3 config
rm -rf ~/.config/i3 ~/.config/i3status

# Remove SSH keys
rm ~/.ssh/id_ed25519*
```

---

## Providing Feedback

Found issues or have suggestions?

1. Check existing issues: https://github.com/yourusername/debian-setup/issues
2. Create a new issue with:
   - Your Debian version
   - Hardware configuration
   - Exact error message
   - Steps to reproduce

