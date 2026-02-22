#!/bin/bash
# 03-security.sh - Harden system security

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

log_info "Starting security hardening..."

# 1. Install firewall
log_info "Installing firewall (UFW)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw

# Enable firewall (idempotent)
ufw --force enable > /dev/null 2>&1 || true

# Default policies
ufw default deny incoming > /dev/null 2>&1 || true
ufw default allow outgoing > /dev/null 2>&1 || true

# Allow SSH (critical - don't lock ourselves out!)
ufw allow 22/tcp > /dev/null 2>&1 || true

# Allow HTTP/HTTPS for development
ufw allow 80/tcp > /dev/null 2>&1 || true
ufw allow 443/tcp > /dev/null 2>&1 || true

log_info "Firewall configured"

# 2. Install fail2ban (intrusion prevention)
log_info "Installing fail2ban..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq fail2ban

# Enable fail2ban service
systemctl enable fail2ban > /dev/null 2>&1 || true
systemctl restart fail2ban > /dev/null 2>&1 || true

# Create local configuration if not exists
if [ ! -f /etc/fail2ban/jail.local ]; then
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@localhost
sendername = Fail2Ban

[sshd]
enabled = true
maxretry = 3
EOF
    systemctl restart fail2ban > /dev/null 2>&1 || true
    log_info "Fail2ban configured"
else
    log_warn "Fail2ban configuration already exists"
fi

# 3. SSH Hardening
log_info "Hardening SSH configuration..."

if [ -f /etc/ssh/sshd_config ]; then
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)
    
    # Apply security settings (idempotent via grep)
    if ! grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    fi
    
    if ! grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config; then
        echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
    fi
    
    if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    fi
    
    if ! grep -q "^X11Forwarding no" /etc/ssh/sshd_config; then
        sed -i 's/^X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
        echo "X11Forwarding no" >> /etc/ssh/sshd_config
    fi
    
    # Test config before restarting
    sshd -t > /dev/null 2>&1 && systemctl restart ssh > /dev/null 2>&1 || log_warn "SSH config test failed, keeping original"
fi

# 4. Install file integrity monitoring
log_info "Installing file integrity monitoring (aide)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq aide aide-common

# Initialize AIDE if not done
if [ ! -f /var/lib/aide/aide.db ]; then
    log_warn "Initializing AIDE database (first run, may take time)..."
    aideinit > /dev/null 2>&1 || true
fi

# 5. Install and configure auditd
log_info "Installing audit daemon..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq auditd audispd-plugins

systemctl enable auditd > /dev/null 2>&1 || true
systemctl restart auditd > /dev/null 2>&1 || true

# 6. Install security tools
log_info "Installing security utilities..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    lynis \
    aide \
    chkrootkit \
    rkhunter \
    gnupg \
    gnupg2

# 7. Configure automatic security updates
log_info "Installing automatic security updates..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unattended-upgrades apt-listchanges

# Enable automatic updates
if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
    if ! grep -q "Unattended-Upgrade::Automatic-Reboot" /etc/apt/apt.conf.d/50unattended-upgrades; then
        echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    fi
fi

# 8. Harden system limits
log_info "Hardening system limits..."
if ! grep -q "^\* soft core" /etc/security/limits.conf; then
    cat >> /etc/security/limits.conf << 'EOF'
* soft core 0
* hard core 0
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
fi

# 9. Install and configure sudo access logging
log_info "Configuring sudo logging..."
if [ ! -f /etc/sudoers.d/sudo-logging ]; then
    echo 'Defaults use_pty' > /etc/sudoers.d/sudo-logging
    echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers.d/sudo-logging
    chmod 440 /etc/sudoers.d/sudo-logging
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_info "Security hardening completed!"
log_warn "Post-hardening recommendations:"
log_warn "  1. Set up SSH key authentication"
log_warn "  2. Run: sudo lynis audit system"
log_warn "  3. Review firewall rules: sudo ufw status"
log_warn "  4. Monitor logs: journalctl -u fail2ban -f"
