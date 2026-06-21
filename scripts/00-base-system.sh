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

# 1. Update package lists (tolerate errors here — we validate/repair sources next)
log_info "Updating package lists..."
apt-get update -qq || log_warn "apt-get update reported errors — validating APT sources next"

# 1b. Validate AND auto-repair the base Debian repo. A fresh netinstall sometimes
# has only a 'deb cdrom:' source (or no mirror), so core packages like
# build-essential/curl/vim appear "not found". If the 'main' component is not
# reachable, add the standard Debian sources for THIS release (codename
# auto-detected) as an additive drop-in, then re-check.
if ! apt-cache show build-essential >/dev/null 2>&1; then
    log_warn "Debian 'main' component not reachable — core packages are invisible to apt."
    DEBIAN_SOURCES="/etc/apt/sources.list.d/debian-main.list"
    CODENAME="$(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}")"
    if [[ -n "$CODENAME" ]]; then
        log_info "Adding standard Debian sources for '$CODENAME' → $DEBIAN_SOURCES"
        cat > "$DEBIAN_SOURCES" << EOF
# Added by debian-setup because the base 'main' component was not configured.
# Delete this file if you manage APT sources yourself.
deb http://deb.debian.org/debian $CODENAME main contrib non-free-firmware
deb http://deb.debian.org/debian $CODENAME-updates main contrib non-free-firmware
deb http://security.debian.org/debian-security $CODENAME-security main contrib non-free-firmware
EOF
        apt-get update -qq || log_warn "apt-get update still reported errors"
    else
        log_warn "Could not detect the Debian codename from /etc/os-release"
    fi
    if ! apt-cache show build-essential >/dev/null 2>&1; then
        log_error "Core packages still not found after configuring standard Debian sources."
        log_error "Check network/DNS, and remove any stale 'deb cdrom:[...]' line from"
        log_error "/etc/apt/sources.list, then re-run. (Delete $DEBIAN_SOURCES to manage sources yourself.)"
        exit 1
    fi
    log_success "Debian 'main' sources configured ($DEBIAN_SOURCES) — core packages now available"
fi

# 2. Install security updates (safe upgrade — doesn't remove packages)
log_info "Installing security updates..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# 3. Core build tools and essentials
log_info "Installing essential build tools..."
ensure_pkgs \
    build-essential \
    linux-headers-amd64 \
    linux-image-amd64 \
    sudo \
    psmisc \
    procps \
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
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    python3-yaml \
    python3-venv \
    unzip

# 4. Hardware firmware packages
# Debian names differ from upstream: there is no "linux-firmware" package on
# Debian — it's firmware-linux* + firmware-misc-nonfree (webcams, wifi, bluetooth,
# misc devices). These live in the non-free-firmware component; if installation
# warns, ensure non-free-firmware is enabled in /etc/apt/sources.list.
log_info "Installing firmware packages..."
ensure_pkgs \
    firmware-linux \
    firmware-linux-nonfree \
    firmware-misc-nonfree || log_warn "Some firmware packages not available (enable the non-free-firmware component in apt sources)"

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
    bind9-dnsutils \
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
