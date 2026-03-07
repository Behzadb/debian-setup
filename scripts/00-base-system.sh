#!/bin/bash
# 00-base-system.sh - Base system optimization and core packages
# Must run FIRST — all other scripts depend on packages installed here.

set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

require_root

# Check Debian version
DEBIAN_VERSION=$(get_debian_version)
log_info "Debian version: $DEBIAN_VERSION"

if [[ "$DEBIAN_VERSION" =~ ^(12|13)$ ]]; then
    log_info "Debian $DEBIAN_VERSION detected — packages optimized for this release"
elif grep -q "bookworm\|trixie\|forky" /etc/os-release; then
    log_warn "Detected Debian testing/unstable — packages may vary"
else
    log_warn "Optimized for Debian 12/13+. Your system may have older packages."
fi

log_section "Base System Setup"

# 1. Update package lists
log_info "Updating package lists..."
apt-get update -qq

# 2. Install security updates (safe upgrade — doesn't remove packages)
log_info "Installing security updates..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# 3. Core build tools and essentials
log_info "Installing essential build tools..."
ensure_pkgs \
    build-essential \
    linux-headers-amd64 \
    linux-image-amd64 \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tmux \
    zsh \
    bash-completion \
    ca-certificates \
    openssl \
    libssl-dev \
    pkg-config \
    apt-transport-https \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    python3-yaml \
    python3-venv \
    unzip

# 4. Hardware firmware packages
log_info "Installing firmware packages..."
ensure_pkgs \
    linux-firmware \
    firmware-linux \
    firmware-linux-nonfree || log_warn "Some firmware packages not available (non-free repos may not be enabled)"

# Install CPU microcode based on vendor
CPU_VENDOR=$(get_cpu_vendor)
if [[ "$CPU_VENDOR" == "intel" ]]; then
    ensure_pkgs intel-microcode || log_warn "intel-microcode not available"
elif [[ "$CPU_VENDOR" == "amd" ]]; then
    ensure_pkgs amd64-microcode || log_warn "amd64-microcode not available"
fi

# 5. System monitoring
log_info "Installing system monitoring tools..."
ensure_pkgs \
    lm-sensors \
    i2c-tools \
    hwinfo \
    inxi

# 6. Core networking (NetworkManager for desktop use)
log_info "Installing core networking..."
ensure_pkgs \
    network-manager \
    wireless-tools \
    wpasupplicant \
    dnsutils \
    traceroute \
    whois \
    iproute2

# 7. Clean up
log_info "Cleaning up package cache..."
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

# 8. System info summary
log_info "System kernel: $(uname -r)"
log_success "Base system setup completed"
log_warn "Recommended: Reboot to load new kernel if it was updated"
