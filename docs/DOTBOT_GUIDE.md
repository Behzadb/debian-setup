# Dotbot Configuration & Management Guide

**Status**: ✅ Complete and Production Ready  
**Date**: February 2026

## 📋 Overview

Dotbot is a lightweight, powerful dotfile manager that:
- Creates symlinks for all configuration files
- Backs up existing configs automatically
- Enables version control via git
- Is idempotent (safe to run multiple times)
- Deploys configs to multiple machines easily

---

## ✅ What Was Implemented

### Configuration File (install.conf.yaml)
The Dotbot configuration manages symlinks for:
```
~/.bashrc              ← config/shell/.bashrc
~/.zshrc               ← config/shell/.zshrc
~/.gitconfig           ← config/shell/.gitconfig   (identity lives in ~/.gitconfig.local)
~/.config/i3/config    ← config/i3/config
~/.config/nvim/init.vim ← config/nvim/init.vim     (reuses ~/.vimrc + ~/.vim plugins)
~/.config/polybar/...  ← config/polybar/ (status bar)
~/.config/kitty/...    ← config/kitty/ (terminal)
... and more (rofi, dunst, btop, lazygit, atuin, starship, betterlockscreen)

Note: ~/.gitconfig is a symlink to the tracked repo file, so your name/email are
NOT written there — they go to ~/.gitconfig.local (git-ignored, pulled in via an
[include] in the tracked .gitconfig). This keeps personal data out of the repo.
```

### Installation Script (scripts/06-dotfiles.sh)
Manages the complete dotfiles setup with:
- Phase 1: Verification of repository structure
- Phase 2: Dotbot installation
- Phase 3: Directory creation
- Phase 4: Backup of existing dotfiles
- Phase 5: Apply configuration
- Phase 6: Verification of symlinks

---

## 🐛 Issues Fixed

### Issue 1: Wrong Configuration Structure
**Problem**: Dotbot error "Configuration file must be a list of tasks"  
**Root Cause**: Top-level structure wasn't a YAML list  
**Solution**: Changed to proper list format with defaults

**Before ❌**:
```yaml
defaults:
  link: ...
configure:
  - shell: ...
```

**After ✅**:
```yaml
- defaults:
    link: ...
- shell:
    - command: ...
```

### Issue 2: Unsafe Operation Order
**Problem**: Files backed up AFTER symlinking (originals lost!)  
**Root Cause**: Operations executed in wrong sequence  
**Solution**: Reordered to safe: create → backup → link → verify

**Correct Order**:
1. Create directories
2. Backup existing files
3. Create symlinks
4. Verify symlinks

### Issue 3: No Error Recovery
**Problem**: Installation failed with no recovery mechanism  
**Root Cause**: Single execution attempt, no retry logic  
**Solution**: Implemented 3x automatic retry with backoff delays

**Before ❌**:
```bash
dotbot -c install.conf.yaml   # Fails once = error
```

**After ✅**:
```bash
for attempt in {1..3}; do
  if dotbot -c install.conf.yaml; then
    break
  fi
  sleep $((attempt * 5))  # Exponential backoff
done
```

### Issue 4: Poor Permission Management
**Problem**: Symlink creation failed due to permission issues  
**Root Cause**: No pre-check of filesystem permissions  
**Solution**: Added permission verification phase

**Added**:
```bash
# Check write permissions
touch "$HOME/.test" 2>/dev/null || {
  echo "ERROR: No write permission to $HOME"
  exit 1
}
```

### Issue 5: Unclear Error Messages
**Problem**: Confusing error messages without actionable steps  
**Root Cause**: Generic error output from dotbot  
**Solution**: Enhanced error messages with solutions

**Before ❌**:
```
Failed to create symlink
```

**After ✅**:
```
Failed to create symlink ~/.bashrc
  Target: /home/user/debian-setup/config/shell/.bashrc
  Error: Permission denied
  Solution: Check file permissions with: ls -la ~/.bashrc
```

---

## 🔧 Configuration Details

### install.conf.yaml Structure

```yaml
# Phase 0: Verification
- shell:
    - command: |
        # Verify repository structure
        # Check directories exist
        # Confirm dotfiles present

# Phase 1-2: Directory creation and backup
- create:
    - ~/.config
    - ~/.config/i3
    - ~/.config/polybar

- shell:
    - command: |
        # Backup existing configs

# Phase 3: Symlink creation
- link:
    ~/.bashrc:
      path: config/shell/.bashrc
    ~/.zshrc:
      path: config/shell/.zshrc
    ~/.gitconfig:
      path: config/shell/.gitconfig
    ~/.config/i3/config:
      path: config/i3/config
    ~/.config/polybar/config.ini:
      path: config/polybar/config.ini

# Phase 4: Verification
- shell:
    - command: |
        # Verify all symlinks created
        # Report success/failures
```

### Link Directive Options

```yaml
link:
  ~/.bashrc:
    path: config/shell/.bashrc
    relink: true          # Replace broken symlinks
    force: false          # Don't overwrite without warning
    create: true          # Create parent directories
```

---

## 🚀 Usage

### Standard Installation
```bash
cd ~/debian-setup
./scripts/06-dotfiles.sh
```

### Dry Run (Preview Changes)
```bash
DRY_RUN=1 ./scripts/06-dotfiles.sh
```

### Post-Installation Management

#### Update Configuration
```bash
# Edit config files
vim ~/.bashrc
vim ~/.config/i3/config

# Changes are automatically tracked by git
git status

# Commit changes
git add config/
git commit -m "Update shell aliases"
```

#### Deploy to Another Machine
```bash
# On new machine
git clone <repo-url> debian-setup
cd debian-setup
./scripts/06-dotfiles.sh
```

#### Add New Dotfile
```bash
# 1. Copy dotfile to config/
cp ~/.myconfig config/shell/.myconfig

# 2. Add to install.conf.yaml
link:
  ~/.myconfig:
    path: config/shell/.myconfig

# 3. Apply
./scripts/06-dotfiles.sh

# 4. Commit
git add config/shell/.myconfig install.conf.yaml
git commit -m "Add myconfig to dotfiles"
```

---

## 🔄 How It Works

### Directory Structure
```
debian-setup/
├── config/
│   ├── i3/
│   │   ├── config              # i3 window manager config
│   │   └── setup-monitors.sh   # Multi-monitor xrandr helper
│   ├── polybar/                # Status bar (replaces i3status)
│   └── shell/
│       ├── .bashrc             # Bash shell config
│       ├── .zshrc              # Zsh shell config
│       └── .gitconfig          # Git configuration
├── scripts/
│   └── 06-dotfiles.sh          # Installation script
├── install.conf.yaml           # Dotbot configuration
└── dotbot/                      # Dotbot manager (auto-installed)
    ├── bin/
    │   └── dotbot              # Main executable
    └── dotbot/                 # Python package
```

### Symlink Examples
After running `./scripts/06-dotfiles.sh`, your home directory contains:

```
~/.bashrc @ → /home/user/debian-setup/config/shell/.bashrc
~/.zshrc @ → /home/user/debian-setup/config/shell/.zshrc
~/.gitconfig @ → /home/user/debian-setup/config/shell/.gitconfig
~/.config/i3/config @ → /home/user/debian-setup/config/i3/config
```

The `@` symbol indicates symlinks.

### Verification Commands

```bash
# Check if symlinks were created
ls -l ~/.bashrc ~/.zshrc ~/.gitconfig

# View symlink target
readlink ~/.bashrc

# Verify all symlinks
ls -la ~/.config/i3/

# Check dotbot status
python3 -c "import yaml; yaml.safe_load(open('install.conf.yaml'))"
```

---

## ⚠️ Troubleshooting

### Symlinks Not Created
```bash
# Check permissions
ls -la ~/debian-setup/config/shell/

# Check YAML syntax
python3 -c "import yaml; yaml.safe_load(open('install.conf.yaml'))"

# Check target paths
ls -la ~/.bashrc  # Should be a symlink (@)
```

### Dotbot Installation Failed
```bash
# Manual fallback
rm -rf dotbot/
git clone --depth 1 https://github.com/anishathalye/dotbot dotbot

# Retry
./scripts/06-dotfiles.sh
```

### Remove Broken Symlinks
```bash
# Clean up broken symlinks
find ~ -type l ! -exec test -e {} \; -delete

# Or specific file
rm ~/.bashrc
./scripts/06-dotfiles.sh  # Relink
```

### View Backup Files
```bash
# Backups created with timestamp
ls -la ~/.bashrc.backup.*
ls -la ~/.config/i3/config.backup.*

# Restore from backup if needed
cp ~/.bashrc.backup.20260219_120000 ~/.bashrc.restore
```

---

## 🔐 Important Notes

### Version Control
- ✅ `config/` directory should be committed to git
- ✅ `dotbot/` can be a git submodule (auto-installed if not present)
- ⚠️ Don't commit backup files to git

### Permissions
- ✅ Symlinks preserve original file permissions
- ✅ Shell configs should have `644` permissions
- ⚠️ SSH configs need `600` permissions

### File Conflicts
If a config file already exists:
1. It will be backed up first
2. Then symlinked
3. Original preserved in `.backup.TIMESTAMP`

---

## 🎓 Best Practices

1. **Keep configs in sync**: Commit changes to git
2. **Use relative paths**: Symlinks use relative paths for portability
3. **Backup frequently**: Backups created automatically
4. **Test on clean system**: Before deploying to production
5. **Document custom configs**: Add comments to edited files

---

## 📞 Support

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| `Configuration file must be a list` | Check install.conf.yaml format |
| Permission denied on symlink | Check write permissions to home |
| Dotbot not found | Run script from debian-setup directory |
| Symlinks not working | Use `readlink ~/.bashrc` to verify |

---

## 📚 Related Documentation

- **Main README**: [README.md](../README.md)
- **Setup Guide**: [QUICK_START.md](QUICK_START.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Dotbot integration complete and production-ready ✅**
