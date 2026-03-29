# Chezmoi Configuration & Management Guide

**Status**: ✅ Complete and Production Ready  
**Date**: March 2026

## 📋 Overview

Chezmoi is an industry-standard, strictly-structured dotfile manager that recently replaced Dotbot in this repository. It:
- Maps configurations natively and idempotently using a mirror directory (`home/`).
- Supports variables, templates, and secret managers.
- Eliminates fragile manual symlink scripts and YAML list management.

---

## 🔧 Repository Structure

The entire configuration system is driven by the `home/` directory in this repository.

```
debian-setup/
├── .chezmoiroot          # Tells Chezmoi to use home/ as the root mapping
├── home/
│   ├── dot_bashrc        # Mapped to ~/.bashrc
│   ├── dot_config/
│   │   ├── i3/config     # Mapped to ~/.config/i3/config
│   │   ├── sway/config   # Mapped to ~/.config/sway/config
```

### Adding New Configurations

To add a new dotfile to the repository to be tracked:

1. Use `chezmoi add`:
   ```bash
   chezmoi add ~/.config/new_app/config
   ```
2. Move it from your local Chezmoi source (`~/.local/share/chezmoi`) into this repository's `home/` directory if you want it tracked centrally.

---

## 🚀 Usage

### Initial Installation Strategy
If you run `./setup.sh` and select Dotfiles, `scripts/06-dotfiles.sh` will automatically:
1. Install the `chezmoi` binary.
2. Run `chezmoi --source . apply` to instantly map the `home/` directory to your actual home directory.

### Manual Synchronization
If you edit a file inside the repository (e.g. `home/dot_bashrc`), you must apply it to your system:
```bash
cd ~/project/debian-setup
chezmoi --source . apply
```

If you edit the live file on your system (e.g. `~/.bashrc`), you must pull the changes back into the repository:
```bash
cp ~/.bashrc ~/project/debian-setup/home/dot_bashrc
git add home/dot_bashrc
git commit -m "Updated bashrc"
```

---

## ⚠️ Troubleshooting

**Q: "Why aren't my changes taking effect?"**  
A: Unlike Dotbot (which created live symlinks), Chezmoi copies files by default. If you edit the file in the repository, you **must** run `chezmoi --source . apply` to overwrite the live file in your `$HOME` directory.

**Q: "How do I make a script executable?"**  
A: Rename the file in the repository to start with `executable_`. For example, `executable_launch.sh` will map to `launch.sh` with `+x` permissions natively applied.
