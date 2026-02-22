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

# 5. Install Kubernetes tools
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

# 6. Install productivity tools
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

# 7. Install version managers (Node, Python, Ruby alternatives)
log_info "Installing version managers (optional)..."
# nvm (Node Version Manager) - optional, lightweight alternative
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh 2>/dev/null | bash || log_warn "nvm installation skipped"
fi

# 8. Install documentation and CLI tools
log_info "Installing CLI utilities..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl \
    wget \
    openssl \
    jq \
    tldr

# 9. Install system profiling tools
log_info "Installing profiling tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    valgrind \
    iotop \
    nethogs \
    linux-tools-generic

# Note: perf-tools-unstable replaced with linux-tools-generic for Debian 13 compatibility

# 10. Install database clients (optional)
log_info "Installing database clients..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    postgresql-client \
    mariadb-client \
    redis-tools

# 10. Install yq (YAML processor) from pip if not available
if ! command -v yq &> /dev/null; then
    log_info "Installing yq from pip..."
    pip3 install --user yq 2>/dev/null || log_warn "yq installation via pip failed, install manually if needed"
fi

# 11. Install speedtest-cli from pip
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
log_warn "  2. Install Python tools: pip3 install --user ipython black flake8 pytest"
log_warn "  3. Configure git: git config --global user.name 'Your Name' && git config --global user.email 'your@email.com'"
log_warn "  4. Ensure Go bin path is in PATH: export PATH=\"\$PATH:\$HOME/go/bin\""
log_warn "  5. Note: mysql-client replaced with mariadb-client in Debian 13"
