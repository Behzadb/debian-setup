#!/bin/bash
# 00-base-system.sh - Base system optimization and core packages

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
fi

# Check Debian version
DEBIAN_VERSION=$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || echo "unknown")
log_info "Debian version: $DEBIAN_VERSION"

if [ "$DEBIAN_VERSION" = "12" ] || [ "$DEBIAN_VERSION" = "13" ] || [ "$DEBIAN_VERSION" = "trixie" ] || [ "$DEBIAN_VERSION" = "forky" ]; then
    log_warn "Detected Debian $DEBIAN_VERSION - packages optimized for this release"
elif ! grep -q "bookworm\|trixie" /etc/os-release; then
    log_warn "This setup is optimized for Debian 12/13+. Your system may have older packages."
fi

log_info "Starting base system setup..."

# 1. Update package lists
log_info "Updating package lists..."
apt-get update -qq

# 2. Upgrade packages (safe upgrade - doesn't remove packages)
log_info "Installing security updates..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# 3. Install essential packages
log_info "Installing essential build tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    build-essential \
    linux-headers-generic \
    linux-image-generic \
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
    python3-yaml

# 4. Install firmware packages for hardware support
log_info "Installing firmware packages for hardware support..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    linux-firmware \
    intel-microcode \
    amd64-microcode \
    firmware-linux \
    firmware-linux-nonfree

# 5. Enable hardware monitoring
log_info "Installing system monitoring tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    lm-sensors \
    i2c-tools \
    hwinfo \
    inxi

# 6. System optimization - disable unnecessary services
log_info "Optimizing system services..."

# 7. Install utility packages
log_info "Installing utility packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    network-manager \
    wireless-tools \
    wpasupplicant \
    dnsutils \
    traceroute \
    whois \
    net-tools

# 8. Clean up
log_info "Cleaning up package cache..."
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

# 9. Check kernel version
log_info "System kernel version:"
uname -r

log_info "Base system setup completed successfully!"
log_warn "Recommended: Reboot system to load new kernel if updated"
