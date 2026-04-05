#!/bin/bash
# 09-verify.sh - Post-installation health check
# Verifies that key services, tools, and configurations are functional.
# Safe to run at any time as a non-destructive audit.
#
# Exit codes:
#   0 = all required checks passed
#   1 = one or more required checks failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

log_section "Post-Installation Health Check"

PASS=0
FAIL=0
WARN=0

# ============================================================================
# Check helpers
# ============================================================================

_check() {
    local name="$1"
    local cmd="$2"
    local severity="${3:-required}"  # required | recommended | optional

    if eval "$cmd" &>/dev/null 2>&1; then
        log_success "$name"
        PASS=$((PASS + 1))
    else
        case "$severity" in
            required)
                log_error "FAIL [required]    $name"
                FAIL=$((FAIL + 1))
                ;;
            recommended)
                log_warn  "WARN [recommended] $name"
                WARN=$((WARN + 1))
                ;;
            optional)
                log_info  "INFO [optional]    $name"
                WARN=$((WARN + 1))
                ;;
        esac
    fi
}

_check_service() {
    local name="$1"
    local service="$2"
    local severity="${3:-required}"
    _check "$name" "systemctl is-active --quiet '$service'" "$severity"
}

_check_cmd() {
    local name="$1"
    local binary="$2"
    local severity="${3:-required}"
    _check "$name" "command -v '$binary'" "$severity"
}

# ============================================================================
# Section 1: Core system services
# ============================================================================
log_info "Checking core services..."

_check_service "Docker daemon"             docker            required
_check_service "SSH daemon"               ssh               required
_check_service "UFW firewall"             ufw               required
_check_service "fail2ban"                 fail2ban          required
_check_service "auditd"                   auditd            recommended
_check_service "TLP power manager"        tlp               recommended
_check_service "systemd-resolved (DNS)"   systemd-resolved  recommended
_check_service "NetworkManager"           NetworkManager    recommended
_check_service "thermald"                 thermald          optional

# ============================================================================
# Section 2: Kubernetes toolchain
# ============================================================================
log_info "Checking Kubernetes tools..."

_check_cmd "kubectl"   kubectl   required
_check_cmd "helm"      helm      required
_check_cmd "kind"      kind      required
_check_cmd "k9s"       k9s       recommended
_check_cmd "stern"     stern     recommended
_check_cmd "kustomize" kustomize recommended
_check_cmd "kubectx"   kubectx   optional
_check_cmd "kubens"    kubens    optional

# ============================================================================
# Section 3: Development tools
# ============================================================================
log_info "Checking development tools..."

_check_cmd "Docker CLI"   docker      required
_check_cmd "Git"          git         required
_check_cmd "Go"           go          required
_check_cmd "Python 3"     python3     required
_check_cmd "Node.js"      node        required
_check_cmd "Terraform"    terraform   recommended
_check_cmd "Ansible"      ansible     recommended
_check_cmd "lazygit"      lazygit     recommended
_check_cmd "Neovim"       nvim        recommended
_check_cmd "tmux"         tmux        recommended
_check_cmd "VSCodium"     codium      optional

# ============================================================================
# Section 4: Modern CLI tools
# ============================================================================
log_info "Checking modern CLI tools..."

_check_cmd "eza (ls replacement)"    eza       recommended
_check_cmd "bat (cat replacement)"   bat       recommended
_check_cmd "delta (diff)"            delta     recommended
_check_cmd "btop (monitor)"          btop      recommended
_check_cmd "ripgrep (grep)"          rg        recommended
_check_cmd "fd (find)"               fd        recommended
_check_cmd "fzf (fuzzy finder)"      fzf       recommended
_check_cmd "zoxide (cd)"             zoxide    recommended
_check_cmd "starship (prompt)"       starship  recommended
_check_cmd "atuin (history)"         atuin     optional
_check_cmd "fnm (node mgr)"          fnm       optional
_check_cmd "uv (python pkgs)"        uv        optional

# ============================================================================
# Section 5: DevSecOps tools
# ============================================================================
log_info "Checking DevSecOps tools..."

_check_cmd "Trivy (scanner)"  trivy  recommended
_check_cmd "Dive (images)"    dive   optional
_check_cmd "SOPS (secrets)"   sops   optional

# ============================================================================
# Section 6: Networking tools
# ============================================================================
log_info "Checking networking tools..."

_check_cmd "mtr"         mtr       required
_check_cmd "nmap"        nmap      required
_check_cmd "tcpdump"     tcpdump   required
_check_cmd "WireGuard"   wg        recommended
_check_cmd "tshark"      tshark    recommended
_check_cmd "iperf3"      iperf3    recommended
_check_cmd "trippy"      trip      optional
_check_cmd "doggo"       doggo     optional

# ============================================================================
# Section 7: Security configuration
# ============================================================================
log_info "Checking security configuration..."

# UFW active with default-deny inbound
_check "UFW default-deny inbound" \
    "ufw status verbose 2>/dev/null | grep -q 'Default: deny (incoming)'" \
    required

# SSH drop-in hardening file exists
_check "SSH hardening drop-in" \
    "[[ -f /etc/ssh/sshd_config.d/90-debian-setup-hardening.conf ]]" \
    recommended

# Password auth disabled in SSH
_check "SSH password auth disabled" \
    "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config.d/90-debian-setup-hardening.conf 2>/dev/null" \
    recommended

# Sudo logging configured
_check "Sudo logging" \
    "[[ -f /etc/sudoers.d/sudo-logging ]]" \
    optional

# ============================================================================
# Section 8: DNS configuration
# ============================================================================
log_info "Checking DNS configuration..."

_check "DNS drop-in config" \
    "[[ -f /etc/systemd/resolved.conf.d/dns-debian-setup.conf ]]" \
    recommended

_check "DNS resolution works (1.1.1.1)" \
    "resolvectl query cloudflare.com &>/dev/null || host cloudflare.com &>/dev/null" \
    required

# ============================================================================
# Section 9: Window manager (at least one must be present)
# ============================================================================
log_info "Checking window manager..."

if command -v sway &>/dev/null; then
    log_success "Sway (Wayland) installed"
    PASS=$((PASS + 1))
    _check_cmd "Waybar"  waybar  recommended
    _check_cmd "Wofi"    wofi    recommended
    _check_cmd "Mako"    mako    recommended
elif command -v i3 &>/dev/null; then
    log_success "i3 (X11) installed"
    PASS=$((PASS + 1))
    _check_cmd "Polybar"   polybar   recommended
    _check_cmd "Rofi"      rofi      recommended
    _check_cmd "Dunst"     dunst     recommended
    _check_cmd "Picom"     picom     optional
else
    log_warn "WARN [recommended] No window manager installed (run 01-window-manager.sh or 01b-wayland-manager.sh)"
    WARN=$((WARN + 1))
fi

_check_cmd "Kitty terminal"  kitty  recommended

# ============================================================================
# Summary
# ============================================================================
log_section "Health Check Summary"

TOTAL=$((PASS + FAIL + WARN))
echo "  Total checks : $TOTAL"
echo "  Passed       : $PASS"
echo "  Warnings     : $WARN"
echo "  Failed       : $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
    log_error "$FAIL required check(s) failed. Review the output above."
    log_info  "Re-run the relevant setup scripts to fix missing components."
    log_info  "Example: sudo bash scripts/02-development-tools.sh"
    exit 1
elif [[ $WARN -gt 0 ]]; then
    log_warn "$WARN optional/recommended item(s) not installed."
    log_success "All required checks passed."
    exit 0
else
    log_success "All $PASS checks passed — system is fully configured."
    exit 0
fi
