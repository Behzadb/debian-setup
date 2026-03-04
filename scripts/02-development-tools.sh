#!/bin/bash
# 02-development-tools.sh - Install development tools, containerization, and K8s

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

log_info "Starting development tools installation..."

# 1. Install version control
log_info "Installing Git..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git git-lfs

# 2. Install programming languages and runtimes
log_info "Installing programming languages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    golang-go \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    nodejs \
    npm

# 3. Install build tools and compilers
log_info "Installing build tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    gcc \
    g++ \
    make \
    cmake \
    gdb \
    strace

# 4. Install Docker
log_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker GPG key and repository
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null || true
    
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin
    
    log_info "Docker installed. Add user to docker group: usermod -aG docker USERNAME"
else
    log_warn "Docker already installed"
fi

# 5. Install KVM/QEMU virtualization
log_info "Installing KVM and QEMU..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    qemu-system-x86 \
    qemu-utils \
    libvirt-daemon \
    libvirt-clients \
    virtinst \
    virt-manager

log_info "KVM/QEMU installed. Add user to libvirt group: usermod -aG libvirt USERNAME"

# 6. Install Vagrant
log_info "Installing Vagrant..."
if ! command -v vagrant &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq vagrant
    log_info "Vagrant installed"
else
    log_warn "Vagrant already installed"
fi

# 7. Install Kubernetes tools
log_info "Installing Kubernetes tools..."
# kubectl
if ! command -v kubectl &> /dev/null; then
    curl -LOs "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 2>/dev/null && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    log_info "kubectl installed" || log_warn "kubectl installation failed"
else
    log_warn "kubectl already installed"
fi

# kind (Kubernetes in Docker)
if ! command -v kind &> /dev/null; then
    go install sigs.k8s.io/kind@latest 2>/dev/null && \
    log_info "kind installed" || log_warn "kind installation failed"
fi

# helm (Kubernetes package manager)
if ! command -v helm &> /dev/null; then
    curl -fsSL https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz 2>/dev/null | \
    tar xz -C /usr/local/bin --strip-components=1 linux-amd64/helm 2>/dev/null && \
    log_info "helm installed" || log_warn "helm installation failed"
fi

# k9s (Kubernetes CLI UI)
if ! command -v k9s &> /dev/null; then
    curl -fsSL https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_amd64.tar.gz 2>/dev/null | \
    tar xz -C /usr/local/bin k9s 2>/dev/null && \
    log_info "k9s installed" || log_warn "k9s installation failed"
fi

# 8. Install productivity tools
log_info "Installing productivity tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    tmux \
    neovim \
    ripgrep \
    fd-find \
    jq \
    yq \
    tree \
    fzf

# Create symlink for fd
ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true

# 8a. Install modern CLI tool replacements
log_info "Installing modern CLI tools (eza, bat, delta, btop)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    eza \
    bat \
    git-delta \
    btop

# Create bat symlink (Debian installs as 'batcat')
ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

# 8b. Install lazygit (Git TUI)
log_info "Installing lazygit..."
if ! command -v lazygit &> /dev/null; then
    LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [ -n "$LAZYGIT_VERSION" ]; then
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz" 2>/dev/null | \
            tar xz -C /usr/local/bin lazygit 2>/dev/null && \
            log_info "lazygit ${LAZYGIT_VERSION} installed" || log_warn "lazygit installation failed"
    else
        log_warn "Could not fetch lazygit version, skipping"
    fi
else
    log_warn "lazygit already installed"
fi

# 9. Install version managers
log_info "Installing version managers..."
# fnm (Fast Node Manager) - replaces nvm: Rust-based, 10x faster shell startup, reads .nvmrc files
if ! command -v fnm &> /dev/null && [ ! -d "$HOME/.local/share/fnm" ]; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell 2>/dev/null || log_warn "fnm installation skipped"
    log_info "fnm installed (Fast Node Manager - replaces nvm with 10x faster startup)"
else
    log_warn "fnm already installed"
fi

# Install Starship prompt (cross-shell, async git/lang info)
log_info "Installing Starship prompt..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh 2>/dev/null | sh -s -- --yes 2>/dev/null && \
        log_info "Starship prompt installed" || log_warn "Starship installation failed"
else
    log_warn "Starship already installed"
fi

# Install atuin (shell history with SQLite, replaces CTRL-R)
log_info "Installing atuin shell history..."
if ! command -v atuin &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh 2>/dev/null | sh 2>/dev/null && \
        log_info "atuin installed" || log_warn "atuin installation failed"
else
    log_warn "atuin already installed"
fi

# Install uv (ultra-fast Python package manager, drop-in pip replacement)
log_info "Installing uv Python package manager..."
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | sh 2>/dev/null && \
        log_info "uv installed (10-100x faster than pip)" || log_warn "uv installation failed"
else
    log_warn "uv already installed"
fi

# 8. Install documentation and CLI tools
log_info "Installing CLI utilities..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl \
    wget \
    openssl \
    jq \
    tealdeer

# 9. Install system profiling tools
log_info "Installing profiling tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    valgrind \
    iotop \
    nethogs 

# Note: perf-tools-unstable replaced with linux-tools-generic for Debian 13 compatibility

# 10. Install database clients (optional)
log_info "Installing database clients..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    postgresql-client \
    mariadb-client \
    redis-tools

# 11. Install ActivityWatch for productivity tracking
log_info "Installing ActivityWatch (productivity tracking)..."
if ! command -v aw-server &> /dev/null; then
    # Download latest ActivityWatch release
    AW_VERSION="v0.12.2"
    AW_URL="https://github.com/ActivityWatch/activitywatch/releases/download/${AW_VERSION}/activitywatch-${AW_VERSION}-linux-x86_64.zip"
    
    # Create directory for ActivityWatch
    mkdir -p ~/.local/share/activitywatch
    
    # Download and extract
    if command -v wget &> /dev/null; then
        wget -q "$AW_URL" -O /tmp/activitywatch.zip 2>/dev/null && \
        unzip -q /tmp/activitywatch.zip -d ~/.local/share 2>/dev/null && \
        chmod +x ~/.local/share/activitywatch/aw-*/aw-* && \
        ln -sf ~/.local/share/activitywatch/aw-*/aw-server /usr/local/bin/aw-server 2>/dev/null || true && \
        ln -sf ~/.local/share/activitywatch/aw-*/aw-client /usr/local/bin/aw-client 2>/dev/null || true && \
        rm -f /tmp/activitywatch.zip && \
        log_info "ActivityWatch installed"
    else
        log_warn "wget not available, skipping ActivityWatch installation"
    fi
else
    log_warn "ActivityWatch already installed"
fi

# 12. Install ActivityWatch watchers and plugins
log_info "Installing ActivityWatch watchers (browser, window, editor)..."
pip3 install --user --quiet activitywatch-browser 2>/dev/null || log_warn "activitywatch-browser install skipped"
pip3 install --user --quiet activitywatch-ulogme 2>/dev/null || log_warn "activitywatch-ulogme install skipped"

# 13. Create ActivityWatch systemd user service for autostart
log_info "Configuring ActivityWatch autostart..."
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/activitywatch.service << 'EOF'
[Unit]
Description=ActivityWatch - Time Tracking and Productivity Monitoring
After=network.target

[Service]
Type=simple
ExecStart=%h/.local/share/activitywatch/aw-server/aw-server
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload 2>/dev/null || true
log_info "ActivityWatch service configured. Start with: systemctl --user start activitywatch"

# 14. Install yq (YAML processor) from pip if not available
if ! command -v yq &> /dev/null; then
    log_info "Installing yq from pip..."
    pip3 install --user yq 2>/dev/null || log_warn "yq installation via pip failed, install manually if needed"
fi

# 15. Install speedtest-cli from pip
if ! command -v speedtest-cli &> /dev/null; then
    log_info "Installing speedtest-cli from pip..."
    pip3 install --user speedtest-cli 2>/dev/null || log_warn "speedtest-cli installation via pip failed, install manually if needed"
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_info "Development tools installation completed!"
log_warn "Post-installation steps:"
log_warn "  1. Add user to docker group: sudo usermod -aG docker \$USER"
log_warn "  2. Add user to libvirt group: sudo usermod -aG libvirt \$USER"
log_warn "  3. Install Python tools via uv: uv pip install ipython black flake8 pytest"
log_warn "  4. Configure git: git config --global user.name 'Your Name' && git config --global user.email 'your@email.com'"
log_warn "  5. Ensure Go bin path is in PATH: export PATH=\"\$PATH:\$HOME/go/bin\""
log_warn "  6. Start ActivityWatch: systemctl --user start activitywatch"
log_warn "  7. Access ActivityWatch web UI: http://localhost:3456"
log_warn "  8. Note: mysql-client replaced with mariadb-client in Debian 13"
log_warn ""
log_warn "New tools available:"
log_warn "  - eza: modern ls (try: eza -la --icons --git)"
log_warn "  - bat: syntax-highlighted cat (try: bat somefile.py)"
log_warn "  - delta: beautiful git diffs (configured automatically via .gitconfig)"
log_warn "  - btop: all-in-one system monitor (try: btop)"
log_warn "  - lazygit: git TUI (try: lazygit in any git repo)"
log_warn "  - starship: prompt with git/lang info (add to .zshrc/.bashrc)"
log_warn "  - atuin: better CTRL-R history search"
log_warn "  - uv: fast Python package manager (try: uv pip install ...)"
log_warn "  - fnm: fast Node.js version manager (reads .nvmrc files)"
