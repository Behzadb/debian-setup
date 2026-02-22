# Debian Setup - Repository Structure Documentation

## Project Layout

```
debian-setup/
│
├── README.md                    # Main project documentation
├── setup.sh                     # Entry point (main orchestrator)
├── setup-helpers.sh            # Utility functions library
├── install.conf.yaml           # Dotbot configuration (dotfiles management)
├── .env.example                # Environment configuration template
├── .gitignore                  # Git ignore patterns
│
├── scripts/                    # Modular installation scripts (numbered order)
│   ├── 00-base-system.sh      # [1] Core system setup
│   ├── 01-window-manager.sh   # [2] Desktop environment (i3)
│   ├── 02-development-tools.sh# [3] Dev tools, Docker, K8s
│   ├── 03-security.sh         # [4] Security hardening
│   ├── 04-power-management.sh # [5] Power & thermal
│   ├── 05-networking.sh       # [6] Network tools & VPN
│   └── 06-dotfiles.sh         # [7] Dotfiles manager (dotbot)
│
├── config/                     # Configuration templates
│   ├── i3/                    # i3 window manager
│   │   ├── config             # Main i3 config
│   │   └── i3status.conf      # Status bar config
│   ├── shell/                 # Shell configurations
│   │   ├── .bashrc            # Bash configuration
│   │   ├── .zshrc             # Zsh configuration
│   │   └── .gitconfig         # Git global config
│   ├── systemd/               # Systemd service configs (future)
│   └── picom/                 # Compositor config (future)
│
├── dotbot/                     # Dotbot (dotfiles manager)
│   ├── bin/
│   │   └── dotbot             # Main executable
│   └── [dotbot files]
│
├── docs/                       # Documentation
│   ├── SELECTIONS.md          # Component rationale & comparison
│   ├── QUICK_START.md         # Getting started guide
│   ├── TROUBLESHOOTING.md     # Common issues & solutions
│   ├── DOTBOT_MANAGEMENT.md   # Dotfiles management guide
│   ├── ARCHITECTURE.md        # Detailed system architecture
│   └── CONTRIBUTING.md        # Contribution guidelines (future)
│
├── tests/                      # Test suite (future)
│   ├── test-base-system.sh
│   ├── test-development-tools.sh
│   └── run-all-tests.sh
│
└── CI/                         # Continuous Integration
    └── .github/workflows/     # GitHub Actions
        └── test.yml          # Automated testing (future)
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

| Script | Installs | Key Decisions |
|--------|----------|---------------|
| `00-base-system.sh` | Kernel, firmware, build tools | Generic kernel for broad hardware support |
| `01-window-manager.sh` | i3 WM, compositor, terminal | Lightweight tiling vs floating alternatives |
| `02-development-tools.sh` | Languages, Docker, K8s | Go/Python/Node.js + Docker + kubectl/helm/kind |
| `03-security.sh` | Firewall, fail2ban, SSH hardening | UFW + fail2ban + AIDE |
| `04-power-management.sh` | TLP, thermald, CPU governors | Balanced power efficiency with performance |
| `05-networking.sh` | VPN, diagnostics, performance tools | WireGuard + full diagnostic suite |
| `06-dotfiles.sh` | Dotbot dotfiles manager | Symlinks configs, idempotent management |

### Config Directory (`config/`)

Pre-configured files that users copy after installation:

```
config/
├── i3/
│   ├── config                 # i3 keybindings, workspaces, layout
│   └── i3status.conf         # System status bar (CPU, battery, etc)
│
├── shell/
│   ├── .bashrc               # Bash aliases, functions, environment
│   ├── .zshrc                # Zsh config with FZF integration
│   └── .gitconfig            # Git user config, aliases, settings
│
├── systemd/                  # Future: systemd service units
│   ├── tlp.service
│   └── custom-daemon.service
│
└── picom/                    # Future: Compositor settings
    └── picom.conf            # Transparency, effects, animation
```

### Docs Directory (`docs/`)

Comprehensive documentation for users:

| Document | Content |
|----------|---------|
| `README.md` | Project overview (in root) |
| `SELECTIONS.md` | Component rationale, pros/cons, when to choose alternatives |
| `QUICK_START.md` | Step-by-step setup guide, post-install configuration |
| `TROUBLESHOOTING.md` | Common issues, solutions, debugging tips |
| `DOTBOT_MANAGEMENT.md` | Dotfiles management with dotbot, workflows, examples |
| `ARCHITECTURE.md` | Deep dive into system design (this file) |

---

## Execution Flow

### When User Runs `setup.sh`:

1. **Pre-flight Checks**
   - Verify root/sudo
   - Check all scripts exist
   - Test internet connectivity
   - Check disk space

2. **User Chooses Mode**
   - Full installation (all modules)
   - Minimal (base only)
   - Custom (pick and choose)

3. **Execute Modules in Order**
   ```bash
   00-base-system.sh
   ├─> 01-window-manager.sh
   │   ├─> 02-development-tools.sh
   │   ├─> 03-security.sh
   │   ├─> 04-power-management.sh
   │   └─> 05-networking.sh
   ```

4. **Post-Installation**
   - Clean up package cache
   - Display next steps
   - Log setup summary

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
      - ~/.config/i3status

  # Link i3 configs
  - link:
      ~/.config/i3/config: config/i3/config
      ~/.config/i3status/config: config/i3/i3status.conf

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
└── i3status.conf    → ~/.config/i3status/config
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

