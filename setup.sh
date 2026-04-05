#!/bin/bash
# setup.sh - Main orchestrator script for Debian system setup
# Enterprise-grade SRE workstation provisioner
#
# Usage: sudo ./setup.sh
# Logs: ./setup-<timestamp>.log

set -euo pipefail

# ============================================================================
# Bootstrap: Resolve paths and source shared library
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$SCRIPT_DIR/scripts"
export LOG_FILE="$SCRIPT_DIR/setup-$(date +%Y%m%d-%H%M%S).log"

# shellcheck source=setup-helpers.sh
source "$SCRIPT_DIR/setup-helpers.sh"

trap '_error_handler $LINENO' ERR

# ============================================================================
# Pre-flight Checks
# ============================================================================
log_section "Pre-flight Checks"

require_root

# Check Debian version
DEBIAN_VERSION=$(get_debian_version)
DEBIAN_NAME=$(grep -oP 'VERSION="\K[^"]+' /etc/os-release 2>/dev/null || echo "unknown")

log_info "Detected Debian version: $DEBIAN_VERSION ($DEBIAN_NAME)"

if [[ "$DEBIAN_VERSION" == "12" || "$DEBIAN_VERSION" == "13" ]]; then
    log_info "✓ Debian $DEBIAN_VERSION supported (optimized packages)"
elif grep -q "bookworm\|trixie\|forky" /etc/os-release; then
    log_warn "Running on Debian testing/unstable — packages may vary"
else
    log_warn "This setup is tested on Debian 12/13. Running on: $DEBIAN_VERSION"
    log_warn "Some packages may not be available or may need manual installation"
fi

log_info "Running as root: OK"

# Verify all scripts exist
log_info "Verifying setup scripts..."
REQUIRED_SCRIPTS=(
    "00-base-system.sh"
    "01-window-manager.sh"
    "02-development-tools.sh"
    "03-security.sh"
    "04-power-management.sh"
    "05-networking.sh"
    "06-dotfiles.sh"
    "07-post-installation.sh"
    "08-generate-docs.sh"
    "09-verify.sh"
)
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -f "$SCRIPTS_PATH/$script" ]]; then
        log_error "Required script not found: $script"
        exit 1
    fi
    log_info "✓ $script"
done

# Check network connectivity
log_info "Checking network connectivity..."
if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
    log_info "Internet connectivity: OK"
else
    log_warn "No internet connectivity detected — some installations may fail"
fi

# Check disk space (minimum 10GB recommended)
log_info "Checking disk space..."
available_space=$(df /home | awk 'NR==2 {print $4}')
if [[ "$available_space" -lt 10485760 ]]; then
    log_warn "Low disk space: $(df -h /home | awk 'NR==2 {print $4}') (recommend 10GB+)"
fi

# ============================================================================
# Setup Configuration Menu
# ============================================================================
log_section "Setup Configuration"

echo "This script will install and configure your Debian system."
echo ""
echo "Available modules:"
echo "  1. Base System (required)"
echo "  2. Window Manager (i3 + Catppuccin)"
echo "  3. Development Tools (Docker, K8s, Terraform, IaC)"
echo "  4. Security Hardening"
echo "  5. Power Management"
echo "  6. Networking Tools (SRE stack)"
echo "  7. Dotfiles Manager (symlinks configs)"
echo "  8. Post-Installation (user setup, SSH, Git)"
echo "  9. Generate System-Reference.md"
echo ""
echo "Choose installation mode:"
echo "  [F] Full installation (all modules, sequential)"
echo "  [C] Custom selection"
echo "  [M] Minimal (base only)"
echo "  [D] Development + Dotfiles (dev focused)"
echo ""
read -rp "Enter choice [F/C/M/D]: " choice

case "${choice,,}" in   # ${,,} lowercases the input
    f)
        log_info "Selected: Full installation"
        MODULES="all"
        ;;
    c)
        log_info "Selected: Custom installation"
        MODULES="custom"
        ;;
    m)
        log_info "Selected: Minimal installation"
        MODULES="minimal"
        ;;
    d)
        log_info "Selected: Development + Dotfiles"
        MODULES="development"
        ;;
    *)
        log_error "Invalid choice: '$choice'"
        exit 1
        ;;
esac

# Display Server Selection
if [[ "$MODULES" == "all" || "$MODULES" == "custom" ]]; then
    echo ""
    echo "Select Display Server / Window Manager:"
    echo "  [1] X11 + i3 (Legacy, robust backwards compatibility)"
    echo "  [2] Wayland + Sway (Modern, tear-free, better battery)"
    read -rp "Enter choice [1/2] (Default: 2): " wm_choice

    if [[ "$wm_choice" == "1" ]]; then
        WM_SCRIPT="01-window-manager.sh"
        WM_NAME="Window Manager (i3/X11)"
    else
        WM_SCRIPT="01b-wayland-manager.sh"
        WM_NAME="Window Manager (Sway/Wayland)"
    fi
fi

# ============================================================================
# Script Runner (sequential, with apt-lock guard)
# ============================================================================
run_script() {
    local script="$1"
    local name="$2"

    if [[ ! -f "$SCRIPTS_PATH/$script" ]]; then
        log_warn "Skipping $name — script not found"
        return 0
    fi

    wait_for_apt_lock
    log_section "Running: $name"

    if bash "$SCRIPTS_PATH/$script" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "$name completed successfully"
    else
        log_error "✗ $name failed (see log for details)"
        return 1
    fi
}

# ============================================================================
# Run Selected Modules (always sequential to avoid apt lock races)
# ============================================================================
log_section "Installation Progress"

case "$MODULES" in
    minimal)
        run_script "00-base-system.sh" "Base System Setup"
        ;;
    all)
        run_script "00-base-system.sh" "Base System Setup"
        run_script "$WM_SCRIPT" "$WM_NAME"
        run_script "02-development-tools.sh" "Development Tools Setup"
        run_script "03-security.sh" "Security Hardening"
        run_script "04-power-management.sh" "Power Management"
        run_script "05-networking.sh" "Networking Tools Setup"

        read -rp "Install Dotfiles Manager? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "06-dotfiles.sh" "Dotfiles Manager" || true
        ;;
    development)
        run_script "00-base-system.sh" "Base System Setup"
        run_script "02-development-tools.sh" "Development Tools Setup"
        run_script "06-dotfiles.sh" "Dotfiles Manager"
        ;;
    custom)
        run_script "00-base-system.sh" "Base System Setup"

        read -rp "Install Window Manager? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "$WM_SCRIPT" "$WM_NAME" || true

        read -rp "Install Development Tools? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "02-development-tools.sh" "Development Tools" || true

        read -rp "Install Security Hardening? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "03-security.sh" "Security" || true

        read -rp "Install Power Management? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "04-power-management.sh" "Power Management" || true

        read -rp "Install Networking Tools? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "05-networking.sh" "Networking" || true

        read -rp "Install Dotfiles Manager? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "06-dotfiles.sh" "Dotfiles Manager" || true

        read -rp "Fetch latest dev tools releases (update-binaries.sh)? (y/n): " ans
        [[ "${ans,,}" == "y" ]] && run_script "update-binaries.sh" "Developer Binaries Update" || true
        ;;
esac

# ============================================================================
# Post-Installation (always runs)
# ============================================================================
log_section "Running Post-Installation Configuration"

if [[ -f "$SCRIPTS_PATH/07-post-installation.sh" ]]; then
    run_script "07-post-installation.sh" "Post-Installation Setup" || log_warn "Post-installation had issues"
else
    log_warn "Post-installation script not found"
fi

# ============================================================================
# System Cleanup
# ============================================================================
log_section "System Cleanup and Finalization"

log_info "Updating system packages..."
apt-get update -qq && apt-get upgrade -y -qq || log_warn "Package upgrade had issues"

log_info "Cleaning up..."
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

# ============================================================================
# Generate System Reference Documentation
# ============================================================================
log_section "Generating System Documentation"

if [[ -f "$SCRIPTS_PATH/08-generate-docs.sh" ]]; then
    run_script "08-generate-docs.sh" "System-Reference.md Generation" || log_warn "Doc generation had issues"
else
    log_warn "Documentation generator not found"
fi

# ============================================================================
# Health Check
# ============================================================================
log_section "Running Health Check"

if [[ -f "$SCRIPTS_PATH/09-verify.sh" ]]; then
    run_script "09-verify.sh" "Post-Installation Health Check" || log_warn "Some health checks failed — review output above"
else
    log_warn "Health check script not found"
fi

# ============================================================================
# Final Summary
# ============================================================================
log_section "Setup Complete!"

# Detect which WM was installed for accurate summary
if command -v sway &>/dev/null; then
    _wm_summary="Sway (Wayland) with Waybar + Wofi"
    _dm_summary="SDDM display manager"
    _wm_config_hint="~/.config/sway/config"
elif command -v i3 &>/dev/null; then
    _wm_summary="i3 (X11) with Polybar + Rofi"
    _dm_summary="LightDM display manager"
    _wm_config_hint="~/.config/i3/config"
else
    _wm_summary="(no window manager — run 01-window-manager.sh or 01b-wayland-manager.sh)"
    _dm_summary="N/A"
    _wm_config_hint="N/A"
fi

echo -e "${_CLR_GREEN}✓ Your Debian SRE workstation is ready!${_CLR_NC}"
echo ""
echo "Installation Summary:"
echo "  • System packages installed and configured (idempotent)"
echo "  • Window Manager: ${_wm_summary}, Catppuccin Mocha theme"
echo "  • Terminal: Kitty (GPU-accelerated, FiraCode Nerd Font)"
echo "  • SRE Stack: Docker, kubectl, k9s, Helm, Terraform, Ansible"
echo "  • Security: UFW, fail2ban, SSH hardening, AIDE, auditd"
echo "  • Networking: WireGuard, mtr, nmap, tcpdump, Wireshark CLI"
echo "  • Power: TLP configured, thermald enabled"
echo "  • Editors: Neovim (LazyVim) + VSCodium + lazygit"
echo ""
echo "After reboot:"
echo "  • Log in via ${_dm_summary}"
echo "  • WM keybindings: ${_wm_config_hint}"
echo "  • Super+Enter → Kitty terminal"
echo "  • Super+d → App launcher"
echo ""
echo "Useful next steps:"
echo "  • Pin binary versions: edit versions.env"
echo "  • Re-run health check: sudo bash scripts/09-verify.sh"
echo "  • Update binaries: bash scripts/update-binaries.sh"
echo "  • Security audit: sudo lynis audit system"
echo ""
echo "Documentation:"
echo "  • System reference: System-Reference.md (auto-generated)"
echo "  • Quick start: docs/QUICK_START.md"
echo "  • Troubleshooting: docs/TROUBLESHOOTING.md"
echo "  • SOPS secrets: docs/SOPS_GUIDE.md"
echo ""
echo "Logs:"
echo "  • Setup log: $LOG_FILE"
echo ""
log_info "Setup script completed at $(date)"
