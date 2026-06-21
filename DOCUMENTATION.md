# 📚 Documentation Guide

Welcome to the Debian Setup documentation. Start here to find what you need.

## 🚀 Getting Started

| If you want to... | Read this |
|------------------|-----------|
| **Understand the project** | [README.md](README.md) - Project overview and features |
| **Install the system** | [QUICK_START.md](docs/QUICK_START.md) - Step-by-step guide |
| **Fix issues** | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common problems & solutions |
| **Understand component choices** | [SELECTIONS.md](docs/SELECTIONS.md) - Why each tool was chosen |
| **Learn Debian 13 compatibility** | [DEBIAN13_COMPATIBILITY.md](docs/DEBIAN13_COMPATIBILITY.md) - Verification & details |
| **Setup dotfiles** | [CHEZMOI_GUIDE.md](docs/CHEZMOI_GUIDE.md) - Configuration management |
| **Understand architecture** | [ARCHITECTURE.md](ARCHITECTURE.md) - System design & extensibility |

---

## 📖 Documentation Files

### Root Level
- **[README.md](README.md)** - Main project documentation (START HERE!)
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design, components, extensibility
- **[FINAL_STATUS.txt](FINAL_STATUS.txt)** - Summary of repository contents

### docs/ Directory
- **[QUICK_START.md](docs/QUICK_START.md)** - Installation guide with examples
- **[SELECTIONS.md](docs/SELECTIONS.md)** - Detailed rationale for each component
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - 40+ common issues & solutions
- **[DEBIAN13_COMPATIBILITY.md](docs/DEBIAN13_COMPATIBILITY.md)** - Debian 13 verification report
- **[CHEZMOI_GUIDE.md](docs/CHEZMOI_GUIDE.md)** - Dotfiles management guide

---

## 🎯 Quick Navigation

### For First-Time Users
1. Read: [README.md](README.md) (5 min)
2. Then: [QUICK_START.md](docs/QUICK_START.md) (10 min)
3. Run: `sudo ./setup.sh` (15-25 min with parallel installation)
4. Optional: Setup monitors with `~/.config/i3/setup-monitors.sh interactive`

### For Decision-Makers
1. Features overview: [README.md](README.md)
2. Component rationale: [SELECTIONS.md](docs/SELECTIONS.md)
3. System design: [ARCHITECTURE.md](ARCHITECTURE.md)

### For Developers
1. Technical details: [SELECTIONS.md](docs/SELECTIONS.md)
2. Source code: [scripts/](scripts/) directory  
3. Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
4. Special features: [ARCHITECTURE.md](ARCHITECTURE.md#special-features--implementation)

### For Troubleshooting
1. Start here: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. If Docker issues: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md#docker)
3. If i3 issues: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md#i3-window-manager)

### For Advanced Users
1. Multi-monitor setup: [ARCHITECTURE.md](ARCHITECTURE.md#3-multi-monitor-support-setup-monitorsh)
2. Binary updates: [ARCHITECTURE.md](ARCHITECTURE.md#5-binary-update-manager-update-binariessh)
3. Status bar (Polybar/Waybar): [ARCHITECTURE.md](ARCHITECTURE.md#2-polybar-status-bar-replaces-i3status)

### For Debian 13 Specific Info
- [DEBIAN13_COMPATIBILITY.md](docs/DEBIAN13_COMPATIBILITY.md) - Full verification report

### For Dotfiles Configuration
- [CHEZMOI_GUIDE.md](docs/CHEZMOI_GUIDE.md) - Setup, usage, and troubleshooting

---

## 📊 Repository Structure

```
debian-setup/
├── README.md                           # Main documentation
├── ARCHITECTURE.md                     # System design & special features
├── setup.sh                            # Main installer (parallel orchestrator)
├── setup-helpers.sh                    # Helper functions
├── .chezmoiroot                        # Points chezmoi at the home/ source root
│
├── scripts/                            # Setup modules
│   ├── 00-base-system.sh              # Core system
│   ├── 01-window-manager.sh           # i3 (X11) + desktop + browser
│   ├── 01b-wayland-manager.sh         # Sway (Wayland) — default display server
│   ├── 02-development-tools.sh        # Languages, Docker, K8s, KVM, Vagrant, ActivityWatch
│   ├── 03-security.sh                 # Security hardening
│   ├── 04-power-management.sh         # Power optimization
│   ├── 05-networking.sh               # Network tools
│   ├── 06-dotfiles.sh                 # chezmoi manager (applies configs into $HOME)
│   ├── 07-post-installation.sh        # Post-setup tasks
│   ├── 08-generate-docs.sh            # Documentation generation
│   ├── 09-verify.sh                   # Installation verification
│   └── update-binaries.sh             # GitHub-based binary updates
│
├── home/                               # chezmoi source root (set via .chezmoiroot)
│   ├── .chezmoiignore                 # Template: selects X11 vs Wayland configs
│   ├── dot_bashrc                     # Bash config
│   ├── dot_zshrc                      # Zsh config
│   ├── dot_gitconfig                  # Git config
│   └── dot_config/
│       ├── i3/
│       │   ├── config                 # i3 keybindings & multi-monitor support
│       │   └── setup-monitors.sh      # Monitor detection & profiles
│       └── sway/config                # Sway config (Wayland)
│
└── docs/                               # Documentation
    ├── QUICK_START.md                 # Getting started
    ├── SELECTIONS.md                  # Component rationale
    ├── TROUBLESHOOTING.md             # Common issues
    ├── DEBIAN13_COMPATIBILITY.md      # Debian 13 verification
    └── CHEZMOI_GUIDE.md               # Dotfiles guide
```

---

## ✨ Key Features Explained

### Modular Installation
Choose what to install:
- **Minimal**: Just base system
- **Full**: Everything
- **Custom**: Pick individual modules
- **Development**: Dev tools + dotfiles

See [SELECTIONS.md](docs/SELECTIONS.md) for component details.

### Idempotent Scripts
All scripts are safe to run multiple times:
```bash
# Run once
sudo ./setup.sh

# Run again - skips already-installed packages
sudo ./setup.sh
```

### Automatic Backup
Before modifying configs, originals are backed up:
```bash
# Backups created with timestamp
~/.bashrc.backup.20260219_120000
~/.config/i3/config.backup.20260219_120000
```

### Version Control Ready
All configs are managed by chezmoi:
```bash
# Changes tracked in git
git status
git commit -m "Update shell aliases"
git push  # Deploy to other machines
```

---

## 🆘 Common Questions

### Where do I start?
→ Read [README.md](README.md), then [QUICK_START.md](docs/QUICK_START.md)

### What if setup fails?
→ Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

### How do I customize configs?
→ Edit files in the `home/` directory, then run `chezmoi --source <repo> apply`; changes are tracked by git

### Can I run this on Debian 12?
→ Yes, tested on Debian 12+. See [DEBIAN13_COMPATIBILITY.md](docs/DEBIAN13_COMPATIBILITY.md)

### Is this production-ready?
→ Yes, fully idempotent and well-tested. See [FINAL_STATUS.txt](FINAL_STATUS.txt)

---

## 📞 Need Help?

1. **Read**: Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) first
2. **Review**: Look at relevant module in [scripts/](scripts/)
3. **Check logs**: `cat setup-*.log` contains detailed output
4. **Ask**: Open an issue with error details and system info

---

## 🔍 Finding Specific Information

| Topic | Document |
|-------|----------|
| Installation steps | [QUICK_START.md](docs/QUICK_START.md) |
| Component choices | [SELECTIONS.md](docs/SELECTIONS.md) |
| Common errors | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| Debian 13 details | [DEBIAN13_COMPATIBILITY.md](docs/DEBIAN13_COMPATIBILITY.md) |
| i3 keybindings | [home/dot_config/i3/config](home/dot_config/i3/config) |
| Git aliases | [home/dot_gitconfig](home/dot_gitconfig) |
| System design | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Dotfiles setup | [CHEZMOI_GUIDE.md](docs/CHEZMOI_GUIDE.md) |

---

**Last Updated**: February 2026  
**Status**: ✅ Production Ready
