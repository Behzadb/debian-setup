#!/bin/bash
# 05-networking.sh - SRE & Network Engineering diagnostic and monitoring toolkit
# Installs comprehensive network tools, VPN, packet analysis, and DNS configuration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

require_root

log_section "SRE Networking Tools Setup"

# Architecture tokens for third-party binary downloads (see 02-development-tools.sh).
case "$(get_arch_gnu)" in
    x86_64)  ARCH_GNU="x86_64";  ARCH_LZ="x86_64" ;;
    aarch64) ARCH_GNU="aarch64"; ARCH_LZ="arm64"  ;;
    *)       ARCH_GNU="";        ARCH_LZ=""        ;;
esac

# 1. Core networking utilities
log_info "Installing core networking utilities..."
ensure_pkgs \
    curl \
    wget \
    iproute2 \
    iputils-ping \
    iputils-tracepath \
    bind9-dnsutils \
    whois \
    netcat-openbsd

# 2. Advanced diagnostic tools (SRE essentials)
log_info "Installing network diagnostic tools..."
ensure_pkgs \
    mtr \
    traceroute \
    tcpdump \
    nmap \
    inetutils-telnet

# Modern diagnostics (trippy, doggo)
log_info "Installing modern diagnostics (trippy, doggo)..."
if ! command_exists trip; then
    TRIP_VERSION=$(curl -s https://api.github.com/repos/fujiapple852/trippy/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$ARCH_GNU" ]]; then
        log_warn "trippy: no prebuilt binary for this architecture — skipping"
    elif [[ -n "${TRIP_VERSION:-}" ]]; then
        # Extract ONLY the 'trip' binary (via --wildcards) — a bare --strip-components
        # would dump LICENSE/README/completions into /usr/local/bin too.
        curl -fsSL "https://github.com/fujiapple852/trippy/releases/download/${TRIP_VERSION}/trippy-${TRIP_VERSION#v}-${ARCH_GNU}-unknown-linux-musl.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin --strip-components=1 --wildcards '*/trip' 2>/dev/null && \
        log_success "trippy ${TRIP_VERSION} installed (modern mtr)" || log_warn "trippy installation failed"
    fi
fi

if ! command_exists doggo; then
    DOGGO_VERSION=$(curl -s https://api.github.com/repos/mr-karan/doggo/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$ARCH_LZ" ]]; then
        log_warn "doggo: no prebuilt binary for this architecture — skipping"
    elif [[ -n "${DOGGO_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/mr-karan/doggo/releases/download/${DOGGO_VERSION}/doggo_${DOGGO_VERSION#v}_Linux_${ARCH_LZ}.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin doggo 2>/dev/null && \
        log_success "doggo ${DOGGO_VERSION} installed (modern dig)" || log_warn "doggo installation failed"
    fi
fi

# 3. VPN and tunneling
log_info "Installing VPN and tunneling tools..."
ensure_pkgs \
    wireguard \
    wireguard-tools \
    openssl

# 4. Network performance testing
log_info "Installing performance testing tools..."
ensure_pkgs \
    iperf3 \
    speedtest-cli || log_warn "speedtest-cli not in apt — install via pip if needed"

# 5. Packet analysis (Wireshark CLI — tshark)
log_info "Installing packet analysis tools..."
# Pre-seed non-root capture BEFORE install so the postinst configures dumpcap
# (sets it up to run under the 'wireshark' group).
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
ensure_pkgs tshark wireshark-common wireshark

# On a re-run where wireshark-common was already installed with setuid declined,
# the preseed above won't re-trigger the postinst — apply it explicitly. (A plain
# `chmod +x dumpcap` does NOT grant capture privileges, so it was a no-op.)
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common >/dev/null 2>&1 || true

# Allow the login user to capture packets without sudo.
if group_exists wireshark; then
    usermod -aG wireshark "${SUDO_USER:-$USER}"
    log_success "Configured non-root packet capture for ${SUDO_USER:-$USER} (re-login required)"
fi

# 6. Proxy and relay tools
log_info "Installing relay tools..."
ensure_pkgs \
    socat \
    proxychains4

# 7. SSL/TLS tools
log_info "Installing SSL/TLS tools..."
ensure_pkgs \
    openssl \
    ca-certificates \
    certbot

# 8. DNS tools
log_info "Installing DNS tools..."
ensure_pkgs bind9-utils

# 9. SSH tools
log_info "Installing SSH tools..."
ensure_pkgs \
    openssh-client \
    openssh-server \
    sshpass

# 10. Network monitoring
log_info "Installing network monitoring tools..."
ensure_pkgs \
    nethogs \
    iftop \
    vnstat || log_warn "Some monitoring tools not available"

# 11. HTTP tools
log_info "Installing HTTP tools..."
ensure_pkgs httpie

# 12. Low-level networking
log_info "Installing advanced networking utilities..."
ensure_pkgs \
    ethtool \
    arp-scan \
    iw \
    wireless-tools \
    rfkill \
    ipset

# 13. Container networking
log_info "Installing container networking tools..."
ensure_pkgs \
    bridge-utils \
    vlan

# ============================================================================
# 14. DNS Configuration (systemd-resolved)
# ============================================================================
log_info "Configuring DNS..."

# systemd-resolved is a separate package since Debian 12 and is not present on a
# minimal install — install it before configuring/restarting it.
ensure_pkgs systemd-resolved || log_warn "systemd-resolved unavailable — DNS drop-in may be inert"

# Use a drop-in file for idempotency instead of editing the main resolved.conf
RESOLVED_DROPIN="/etc/systemd/resolved.conf.d/dns-debian-setup.conf"

if [[ ! -f "$RESOLVED_DROPIN" ]]; then
    mkdir -p /etc/systemd/resolved.conf.d
    cat > "$RESOLVED_DROPIN" << 'EOF'
# DNS configuration — generated by debian-setup
# Using privacy-focused and security-focused resolvers
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=9.9.9.9 149.112.112.112
DNSSEC=yes
EOF
    restart_service systemd-resolved
    log_success "DNS configured via $RESOLVED_DROPIN"
else
    log_info "DNS drop-in config already exists"
fi

# Networking aliases have been relocated directly to config/shell/.bashrc
# and config/shell/.zshrc so they are immediately available in non-login shells.

# ============================================================================
# 15. Mobile broadband / WWAN (ModemManager) — only if a cellular modem exists
# ============================================================================
log_info "Checking for a WWAN / cellular modem..."
# USB vendor IDs of common WWAN modules: Fibocom, Quectel, Sierra, Huawei,
# Dell/HP rebrands, Qualcomm. Plus lspci text and a wwan* netdev as fallbacks.
WWAN_VENDORS='2cb7|2c7c|1199|1bc7|12d1|413c|03f0|1e0e'
if (command_exists lsusb && lsusb 2>/dev/null | grep -qiE "ID (${WWAN_VENDORS}):") || \
   (command_exists lspci && lspci 2>/dev/null | grep -qiE 'modem|wwan|cellular|LTE|mobile broadband|5G') || \
   ls -d /sys/class/net/ww* >/dev/null 2>&1; then
    log_info "WWAN modem detected — installing ModemManager + tools"
    # mbim (modern modems) + qmi (Qualcomm) utils; usb-modeswitch flips dongles
    # from storage to modem mode. NetworkManager (base) drives the connection.
    ensure_pkgs modemmanager libmbim-utils libqmi-utils usb-modeswitch usb-modeswitch-data
    enable_service ModemManager
    start_service ModemManager
    # Optional GUI to manage the modem / SMS / signal as a user (works in i3)
    ensure_pkgs modem-manager-gui || log_warn "modem-manager-gui not in apt — use nmtui/nmcli/mmcli"
    log_success "WWAN support installed"
    log_warn "Manage as a user:  nmtui  → add 'Mobile broadband' (enter your APN),"
    log_warn "  or  mmcli -L  /  modem-manager-gui ; status:  mmcli -m 0"
else
    log_info "No WWAN/cellular modem detected — skipping ModemManager"
    log_info "  (If you add a modem later: sudo apt install modemmanager libmbim-utils libqmi-utils)"
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_section "Networking Tools Complete"
log_info "SRE networking stack installed:"
log_info "  Diagnostics: mtr, traceroute, tcpdump, nmap, tshark"
log_info "  VPN: WireGuard"
log_info "  Performance: iperf3, speedtest-cli"
log_info "  Monitoring: nethogs, iftop, vnstat"
log_info "  DNS: Cloudflare (1.1.1.1) + Quad9 (9.9.9.9) fallback"
log_warn "Recommendations:"
log_warn "  1. Test: mtr 8.8.8.8"
log_warn "  2. Stats: vnstat -h"
log_warn "  3. Monitor: nethogs"
log_warn "  4. VPN: sudo wg-quick up wg0 (after config)"
