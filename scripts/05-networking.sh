#!/bin/bash
# 05-networking.sh - Install networking and diagnostic tools

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root"
    exit 1
fi

log_info "Starting networking tools setup..."

# 1. Core networking utilities
log_info "Installing core networking utilities..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl \
    wget \
    net-tools \
    iputils-ping \
    iputils-tracepath \
    dnsutils \
    whois \
    netcat-openbsd

# 2. Advanced diagnostic tools
log_info "Installing network diagnostic tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    mtr \
    traceroute \
    tcpdump \
    nmap \
    nc \
    telnet

# 3. VPN and tunneling tools
log_info "Installing VPN and tunneling tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    wireguard \
    wireguard-tools \
    openssl

# 4. Network performance testing
log_info "Installing performance testing tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    iperf3 \
    speedtest-cli

# 5. Packet analysis and manipulation
log_info "Installing packet tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    tshark \
    wireshark-common

# 6. Proxy and relay tools
log_info "Installing relay tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    socat \
    proxychains4

# 7. SSL/TLS tools
log_info "Installing SSL/TLS tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    openssl \
    ca-certificates \
    certbot

# 8. DNS and DHCP tools
log_info "Installing DNS tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    bind9-utils \
    dig

# 9. SSH tools (already installed but ensure)
log_info "Installing SSH tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    openssh-client \
    openssh-server \
    sshpass

# 10. Network configuration and monitoring
log_info "Installing network monitoring tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    ifstat \
    nethogs \
    iftop \
    vnstat

# 11. Packet editing and HTTP tools
log_info "Installing HTTP/packet tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    httpie \
    curl

# Note: speedtest-cli now installed via pip from 02-development-tools.sh for better Debian 13 compatibility

# 12. Low-level networking tools
log_info "Installing advanced networking utilities..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    ethtool \
    arp-scan \
    iw \
    wireless-tools \
    rfkill

# 13. IP and routing tools
log_info "Installing IP tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    iproute2 \
    ipset

# 14. Container networking (related to K8s work)
log_info "Installing container networking tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    bridge-utils \
    vlan

# 15. Configure DNS (systemd-resolved or custom)
log_info "Configuring DNS..."

if ! grep -q "^\[Resolve\]" /etc/systemd/resolved.conf 2>/dev/null; then
    cat >> /etc/systemd/resolved.conf << 'EOF'

# DNS configuration for secure and private resolution
[Resolve]
# Cloudflare DNS (1.1.1.1) - fast and privacy-focused
DNS=1.1.1.1 1.0.0.1
# Fallback: Quad9 (9.9.9.9) - security-focused
FallbackDNS=9.9.9.9 149.112.112.112
DNSSEC=yes
DNSSECNegativeTrustAnchors=
EOF
fi

systemctl restart systemd-resolved > /dev/null 2>&1 || true

# 16. Create useful networking aliases
log_info "Setting up networking utilities..."

if [ ! -f /etc/profile.d/networking-aliases.sh ]; then
    cat > /etc/profile.d/networking-aliases.sh << 'EOF'
# Useful networking aliases
alias myip='curl -s https://api.ipify.org && echo'
alias myip4='curl -s https://ipv4.icanhazip.com'
alias myip6='curl -s https://ipv6.icanhazip.com'
alias ports='netstat -tulanp'
alias ping='ping -c 5'
alias fastping='ping -c 100 -s.2'
alias netstat='ss'
EOF
    chmod +x /etc/profile.d/networking-aliases.sh
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_info "Networking tools installation completed!"
log_warn "Post-setup recommendations:"
log_warn "  1. Test connectivity: mtr 8.8.8.8"
log_warn "  2. View network stats: vnstat -h"
log_warn "  3. Monitor active connections: nethogs"
log_warn "  4. Setup VPN: sudo wg-quick up wg0 (after config)"
log_warn "  5. Test DNS: nslookup google.com"
log_warn "  6. Note: speedtest-cli installed via pip for Debian 13 compatibility"
