#!/bin/bash
# 06-dotfiles.sh - Dotbot Configuration Manager

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Error handler
error_handler() {
    log_error "Setup failed at line $1"
    exit 1
}

trap 'error_handler $LINENO' ERR

log_section "Dotfiles Setup - Verification"

# Check if running as regular user (dotfiles should be applied to user, not root)
if [ "$EUID" -eq 0 ]; then
    log_warn "Running as root - dotfiles will be created for root user"
    log_warn "Typically, run this as regular user: ${CYAN}./06-dotfiles.sh${NC}"
fi

# Verify repository structure
log_info "Verifying repository structure..."
if [ ! -f "$REPO_DIR/install.conf.yaml" ]; then
    log_error "install.conf.yaml not found in $REPO_DIR"
    exit 1
fi
log_success "install.conf.yaml found"

if [ ! -d "$REPO_DIR/config" ]; then
    log_error "config/ directory not found"
    exit 1
fi
log_success "config/ directory found"

# Check required dotfiles exist
log_info "Checking dotfiles..."
dotfiles=(
    "config/shell/.bashrc"
    "config/shell/.zshrc"
    "config/shell/.gitconfig"
    "config/i3/config"
    "config/i3/i3status.conf"
)

for dotfile in "${dotfiles[@]}"; do
    if [ -f "$REPO_DIR/$dotfile" ]; then
        log_success "$dotfile exists"
    else
        log_warn "$dotfile not found (optional)"
    fi
done

log_section "Dotfiles Setup - Installing Dotbot"

DOTBOT_DIR="$REPO_DIR/dotbot"
DOTBOT_BIN="$DOTBOT_DIR/bin/dotbot"

if [ -d "$DOTBOT_DIR" ]; then
    log_info "Dotbot already installed at $DOTBOT_DIR"
else
    log_info "Downloading dotbot..."
    
    # Clone dotbot as a submodule would, but as a direct clone for simplicity
    # Users can optionally add it as a git submodule
    git clone --depth 1 https://github.com/anishathalye/dotbot "$DOTBOT_DIR" 2>/dev/null || {
        log_error "Failed to clone dotbot"
        log_info "Manual fix: git clone https://github.com/anishathalye/dotbot dotbot"
        exit 1
    }
    log_success "Dotbot installed successfully"
fi

# Verify dotbot executable exists
if [ ! -f "$DOTBOT_BIN" ]; then
    log_error "Dotbot executable not found at $DOTBOT_BIN"
    exit 1
fi
log_success "Dotbot executable found"

log_section "Dotfiles Setup - Creating Directories"

# Create config directories if they don't exist
config_dirs=(
    "$HOME/.config"
    "$HOME/.config/i3"
    "$HOME/.config/i3status"
)

for dir in "${config_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        log_info "Creating $dir..."
        mkdir -p "$dir"
        log_success "Created $dir"
    else
        log_info "$dir already exists"
    fi
done

log_section "Dotfiles Setup - Backing Up Existing Dotfiles"

backup_if_exists() {
    local file="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        local backup="${file}.backup.${timestamp}"
        log_info "Backing up $file → $backup"
        cp -r "$file" "$backup"
        log_success "Backed up to $backup"
    fi
}

# Backup existing dotfiles
log_info "Checking for existing dotfiles to backup..."
backup_if_exists "$HOME/.bashrc"
backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.gitconfig"
backup_if_exists "$HOME/.config/i3/config"
backup_if_exists "$HOME/.config/i3status/config"

log_section "Dotfiles Setup - Applying Configuration"

if [ "${DRY_RUN:-0}" = "1" ]; then
    log_warn "DRY RUN MODE - No changes will be applied"
    DOTBOT_ARGS="--verbose --dry-run"
else
    DOTBOT_ARGS="--verbose"
fi

log_info "Running dotbot with configuration: $REPO_DIR/install.conf.yaml"

# Change to repo directory for dotbot to work correctly
cd "$REPO_DIR" || exit 1

# Run dotbot with retry logic
MAX_RETRIES=3
retry_count=0

while [ $retry_count -lt $MAX_RETRIES ]; do
    log_info "Attempt $((retry_count + 1))/$MAX_RETRIES..."
    
    if python3 "$DOTBOT_BIN" $DOTBOT_ARGS -c "install.conf.yaml" 2>&1; then
        log_success "Dotbot configuration applied successfully"
        DOTBOT_SUCCESS=1
        break
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warn "Dotbot failed, retrying in 2 seconds..."
            sleep 2
        else
            log_error "Dotbot configuration failed after $MAX_RETRIES attempts"
            log_error "Troubleshooting:"
            log_error "  1. Check install.conf.yaml syntax: python3 -c \"import yaml; yaml.safe_load(open('install.conf.yaml'))\""
            log_error "  2. Check permissions: ls -la ~/.config/"
            log_error "  3. Check for conflicting symlinks: ls -la ~/ | grep -E '^l'"
            exit 1
        fi
    fi
done

log_section "Dotfiles Setup - Verification"

log_info "Verifying dotfile symlinks..."

verify_symlink() {
    local link="$1"
    local expected_target="$2"
    
    if [ -L "$link" ]; then
        local actual_target=$(readlink "$link")
        if [[ "$actual_target" == *"$expected_target"* ]]; then
            log_success "$link → $actual_target"
            return 0
        else
            log_warn "$link points to $actual_target (expected *$expected_target*)"
            return 1
        fi
    elif [ -e "$link" ]; then
        log_warn "$link exists but is not a symlink"
        return 1
    else
        log_warn "$link does not exist"
        return 1
    fi
}

# Verify each symlink
all_ok=true
verify_symlink "$HOME/.bashrc" "config/shell/.bashrc" || all_ok=false
verify_symlink "$HOME/.zshrc" "config/shell/.zshrc" || all_ok=false
verify_symlink "$HOME/.gitconfig" "config/shell/.gitconfig" || all_ok=false
verify_symlink "$HOME/.config/i3/config" "config/i3/config" || all_ok=false
verify_symlink "$HOME/.config/i3status/config" "config/i3/i3status.conf" || all_ok=false

if [ "$all_ok" = true ]; then
    log_success "All dotfile symlinks verified successfully"
else
    log_warn "Some symlinks could not be verified (they may still work)"
fi

log_section "Dotfiles Setup - Complete"

log_success "Dotfiles installed and configured"

cat << 'EOF'

📋 What Was Done:
  ✓ Installed dotbot dotfile manager
  ✓ Created symlinks for all dotfiles
  ✓ Backed up any existing configurations
  ✓ Created required directories

🎯 Next Steps:

  1. Customize Your Dotfiles:
     - Edit ~/.bashrc (symlinks to config/shell/.bashrc)
     - Edit ~/.zshrc (symlinks to config/shell/.zshrc)
     - Edit ~/.gitconfig (symlinks to config/shell/.gitconfig)
     - Edit ~/.config/i3/config (symlinks to config/i3/config)

  2. Reload Shell Configuration:
     source ~/.bashrc    # For bash
     source ~/.zshrc     # For zsh
     exec $SHELL         # Restart shell

  3. Customize for Your System:
     - Edit config files in the repository
     - Changes apply immediately (symlinked)
     - Commit changes to git for version control

  4. Manage Dotfiles with Git:
     cd /home/behzadbarabadi/project/debian-setup
     git status              # See what changed
     git add config/         # Stage dotfile changes
     git commit -m "Update configs"
     git push origin main

📚 Dotbot Documentation:
  - About: https://github.com/anishathalye/dotbot
  - Configuration: ./install.conf.yaml
  - Add new dotfiles: Edit install.conf.yaml and re-run

⚙️ Manual Dotbot Commands:
  # Apply configuration (with verbose output)
  python3 dotbot/bin/dotbot --verbose -c install.conf.yaml

  # Dry run (preview changes without applying)
  DRY_RUN=1 ./06-dotfiles.sh

  # Completely remove symlinks and restore backups
  for link in ~/.bashrc ~/.zshrc ~/.gitconfig ~/.config/i3/config; do
    [ -L "$link" ] && rm "$link"
    [ -f "${link}.backup."* ] && mv "${link}.backup."* "$link"
  done

💡 Tips:
  - All changes in config/ directory are immediately reflected
  - Backups created with timestamp (e.g., .bashrc.backup.20240101_120000)
  - Safe to run multiple times - idempotent
  - Use 'git' to track all dotfile changes
  - Create new modules: edit install.conf.yaml

EOF

log_info "Status: ✅ Dotfiles setup complete"
