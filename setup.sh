#!/bin/bash
# setup.sh - Main orchestrator script for system setup

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$SCRIPT_DIR/scripts"
LOG_FILE="$SCRIPT_DIR/setup-$(date +%Y%m%d-%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}  $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n" | tee -a "$LOG_FILE"
}

# Error handler
error_handler() {
    log_error "Setup failed at line $1"
    log_error "Check log file: $LOG_FILE"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Pre-flight checks
log_section "Pre-flight Checks"

if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use: sudo ./setup.sh)"
    exit 1
fi

# Check Debian version
DEBIAN_VERSION=$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || echo "unknown")
DEBIAN_NAME=$(grep -oP 'VERSION="\K[^"]+' /etc/os-release 2>/dev/null || echo "unknown")

log_info "Detected Debian version: $DEBIAN_VERSION ($DEBIAN_NAME)"

# Verify compatibility
if [ "$DEBIAN_VERSION" = "12" ] || [ "$DEBIAN_VERSION" = "13" ]; then
    log_info "✓ Debian $DEBIAN_VERSION supported (optimized packages)"
elif grep -q "bookworm\|trixie\|forky" /etc/os-release; then
    log_warn "Running on Debian testing/unstable - packages may vary"
else
    log_warn "This setup is tested on Debian 12/13. Running on: $DEBIAN_VERSION"
    log_warn "Some packages may not be available or may need manual installation"
fi

log_info "Running as root: OK"

# Verify all scripts exist
log_info "Verifying setup scripts..."
for script in 00-base-system.sh 01-window-manager.sh 02-development-tools.sh 03-security.sh 04-power-management.sh 05-networking.sh 06-dotfiles.sh; do
    if [ ! -f "$SCRIPTS_PATH/$script" ]; then
        log_error "Required script not found: $script"
        exit 1
    fi
    log_info "✓ $script"
done

# Check network connectivity
log_info "Checking network connectivity..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    log_info "Internet connectivity: OK"
else
    log_warn "No internet connectivity detected - some installations may fail"
fi

# Check disk space (minimum 10GB recommended)
log_info "Checking disk space..."
available_space=$(df /home | awk 'NR==2 {print $4}')
if [ "$available_space" -lt 10485760 ]; then
    log_warn "Low disk space: $(df -h /home | awk 'NR==2 {print $4}') (recommend 10GB+)"
fi

# Menu for selective installation
log_section "Setup Configuration"

echo "This script will install and configure your Debian system."
echo ""
echo "Available modules:"
echo "  1. Base System (required)"
echo "  2. Window Manager (i3)"
echo "  3. Development Tools"
echo "  4. Security Hardening"
echo "  5. Power Management"
echo "  6. Networking Tools"
echo "  7. Dotfiles Manager (symlinks configs)"
echo ""
echo "Choose installation mode:"
echo "  [F] Full installation (all modules)"
echo "  [C] Custom selection"
echo "  [M] Minimal (base only)"
echo "  [D] Development + Dotfiles (dev focused)"
echo ""
read -p "Enter choice [F/C/M/D]: " choice

case "$choice" in
    F|f)
        log_info "Selected: Full installation"
        MODULES="all"
        ;;
    C|c)
        log_info "Selected: Custom installation"
        MODULES="custom"
        ;;
    M|m)
        log_info "Selected: Minimal installation"
        MODULES="minimal"
        ;;
    D|d)
        log_info "Selected: Development + Dotfiles"
        MODULES="development"
        ;;
    *)
        log_error "Invalid choice"
        exit 1
        ;;
esac

# Run selected modules
log_section "Installation Progress"

run_script() {
    local script=$1
    local name=$2
    
    if [ ! -f "$SCRIPTS_PATH/$script" ]; then
        log_warn "Skipping $name - script not found"
        return
    fi
    
    log_info "Running: $name..."
    if bash "$SCRIPTS_PATH/$script" 2>&1 | tee -a "$LOG_FILE"; then
        log_info "✓ $name completed successfully"
    else
        log_error "✗ $name failed (see log for details)"
        return 1
    fi
}

case "$MODULES" in
    minimal)
        run_script "00-base-system.sh" "Base System Setup"
        ;;
    all)
        run_script "00-base-system.sh" "Base System Setup"
        run_script "01-window-manager.sh" "Window Manager (i3) Setup"
        run_script "02-development-tools.sh" "Development Tools Setup"
        run_script "03-security.sh" "Security Hardening"
        run_script "04-power-management.sh" "Power Management"
        run_script "05-networking.sh" "Networking Tools Setup"
        read -p "Install Dotfiles Manager? (y/n): " ans && [ "$ans" = "y" ] && run_script "06-dotfiles.sh" "Dotfiles Manager" || true
        ;;
    development)
        run_script "00-base-system.sh" "Base System Setup"
        run_script "02-development-tools.sh" "Development Tools Setup"
        run_script "06-dotfiles.sh" "Dotfiles Manager"
        ;;
    custom)
        read -p "Install Window Manager? (y/n): " ans && [ "$ans" = "y" ] && run_script "01-window-manager.sh" "Window Manager" || true
        read -p "Install Development Tools? (y/n): " ans && [ "$ans" = "y" ] && run_script "02-development-tools.sh" "Development Tools" || true
        read -p "Install Security Hardening? (y/n): " ans && [ "$ans" = "y" ] && run_script "03-security.sh" "Security" || true
        read -p "Install Power Management? (y/n): " ans && [ "$ans" = "y" ] && run_script "04-power-management.sh" "Power Management" || true
        read -p "Install Networking Tools? (y/n): " ans && [ "$ans" = "y" ] && run_script "05-networking.sh" "Networking" || true
        read -p "Install Dotfiles Manager? (y/n): " ans && [ "$ans" = "y" ] && run_script "06-dotfiles.sh" "Dotfiles Manager" || true
        ;;
esac

# ============================================================================
# Automatic Post-Installation Configuration
# ============================================================================

log_section "Running Post-Installation Configuration"

# Always run post-installation script automatically
if [ -f "$REPO_DIR/scripts/07-post-installation.sh" ]; then
    run_script "07-post-installation.sh" "Post-Installation Setup" || log_warn "Post-installation script had issues"
else
    log_warn "Post-installation script not found"
fi

# Post-installation
log_section "System Cleanup and Finalization"

log_info "Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq || log_warn "Package upgrade had issues"

log_info "Cleaning up..."
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

# Summary
log_section "Setup Complete!"

echo -e "${GREEN}✓ Your Debian system is ready!${NC}"
echo ""
echo "Installation Summary:"
echo "  • System packages installed and configured"
echo "  • Window Manager (i3) installed with login manager (lightdm)"
echo "  • Development tools configured"
echo "  • Security hardening applied"
echo "  • Power management configured"
echo "  • Vim and plugins installed"
echo "  • SSH keys generated"
echo "  • Git configured"
echo ""
echo "After reboot:"
echo "  • Log in via lightdm (graphical login screen)"
echo "  • Use i3 window manager (keyboard-driven interface)"
echo "  • i3 keybindings: https://i3wm.org/docs/userguide.html"
echo ""
echo "Useful Commands:"
echo "  • Check SSH key: cat ~/.ssh/id_ed25519.pub"
echo "  • Test Docker: docker run hello-world"
echo "  • Test Kubernetes: kind create cluster --name test"
echo "  • Verify dotfiles: ls -la ~/ | grep '^l'"
echo ""
echo "Logs:"
echo "  • Setup log: $LOG_FILE"
echo ""
echo "Documentation:"
echo "  • Getting started: docs/QUICK_START.md"
echo "  • Troubleshooting: docs/TROUBLESHOOTING.md"
echo "  • Component choices: docs/SELECTIONS.md"
log_info "Setup script completed at $(date)"
