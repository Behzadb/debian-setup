#!/bin/bash
# 02-development-tools.sh - Development tools, containerization, K8s, and IaC
# SRE-focused toolchain for infrastructure engineering.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

require_root

log_section "Development Tools Installation"

# 1. Version control
log_info "Installing Git..."
ensure_pkgs git git-lfs

# 2. Programming languages and runtimes
log_info "Installing programming languages..."
ensure_pkgs \
    golang-go \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    nodejs \
    npm

# 3. Build tools and compilers
log_info "Installing build tools..."
ensure_pkgs \
    gcc \
    g++ \
    make \
    cmake \
    gdb \
    strace

# 4. Docker
log_info "Installing Docker..."
if ! command_exists docker; then
    # Add Docker GPG key and repository (modern approach)
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
        gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    ensure_pkgs \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    log_success "Docker installed"
else
    log_info "Docker already installed"
fi

# 5. KVM/QEMU virtualization
log_info "Installing KVM and QEMU..."
ensure_pkgs \
    qemu-system-x86 \
    qemu-utils \
    libvirt-daemon \
    libvirt-clients \
    virtinst \
    virt-manager

# 6. Vagrant
log_info "Installing Vagrant..."
if ! command_exists vagrant; then
    ensure_pkgs vagrant
else
    log_info "Vagrant already installed"
fi

# 7. Kubernetes tools
log_info "Installing Kubernetes tools..."

# kubectl
if ! command_exists kubectl; then
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null)
    if [[ -n "${KUBECTL_VERSION:-}" ]]; then
        curl -LOs "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" 2>/dev/null && \
        chmod +x kubectl && \
        mv kubectl /usr/local/bin/kubectl && \
        log_success "kubectl ${KUBECTL_VERSION} installed" || log_warn "kubectl installation failed"
    fi
else
    log_info "kubectl already installed"
fi

# kind (Kubernetes in Docker)
if ! command_exists kind; then
    KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${KIND_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64" \
            -o /usr/local/bin/kind 2>/dev/null && \
        chmod +x /usr/local/bin/kind && \
        log_success "kind ${KIND_VERSION} installed" || log_warn "kind installation failed"
    fi
else
    log_info "kind already installed"
fi

# helm (Kubernetes package manager)
if ! command_exists helm; then
    HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${HELM_VERSION:-}" ]]; then
        curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin --strip-components=1 linux-amd64/helm 2>/dev/null && \
        log_success "helm ${HELM_VERSION} installed" || log_warn "helm installation failed"
    fi
else
    log_info "helm already installed"
fi

# k9s (Kubernetes CLI UI)
if ! command_exists k9s; then
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${K9S_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin k9s 2>/dev/null && \
        log_success "k9s ${K9S_VERSION} installed" || log_warn "k9s installation failed"
    fi
else
    log_info "k9s already installed"
fi

# Additional K8s tools (stern, kustomize, kubestr)
log_info "Installing additional Kubernetes utilities..."
# Stern
if ! command_exists stern; then
    STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${STERN_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin stern 2>/dev/null && \
        log_success "stern ${STERN_VERSION} installed"
    fi
fi

# Kustomize
if ! command_exists kustomize; then
    ensure_pkgs kustomize 2>/dev/null || {
        log_info "kustomize not in apt — installing from official installer..."
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash 2>/dev/null || true
        [[ -f kustomize ]] && mv kustomize /usr/local/bin/ && log_success "kustomize installed"
    }
fi

# Kubestr (storage benchmark)
if ! command_exists kubestr; then
    KUBESTR_VERSION="v0.4.48"
    curl -fsSL "https://github.com/kastenhq/kubestr/releases/download/${KUBESTR_VERSION}/kubestr_${KUBESTR_VERSION#v}_Linux_amd64.tar.gz" 2>/dev/null | \
    tar xz -C /usr/local/bin kubestr 2>/dev/null && log_success "kubestr installed"
fi

# ============================================================================
# 8. Infrastructure as Code (IaC) — SRE Essentials
# ============================================================================
log_section "Infrastructure as Code Tools"

# Terraform (via HashiCorp APT repository)
log_info "Installing Terraform..."
if ! command_exists terraform; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

    apt-get update -qq
    ensure_pkgs terraform
    log_success "Terraform installed"
else
    log_info "Terraform already installed: $(terraform version -json 2>/dev/null | head -1 || echo 'version unknown')"
fi

# Ansible
log_info "Installing Ansible..."
ensure_pkgs ansible || {
    log_info "Ansible not in apt — installing via pip..."
    pip3 install --quiet ansible 2>/dev/null || log_warn "Ansible installation failed"
}

# 9. Productivity tools (modern CLI replacements)
log_info "Installing productivity tools..."
ensure_pkgs \
    tmux \
    neovim \
    ripgrep \
    fd-find \
    jq \
    yq \
    tree \
    fzf

# Create symlink for fd (Debian installs as 'fdfind')
ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true

# Modern CLI tool replacements
log_info "Installing modern CLI tools (eza, bat, delta)..."
ensure_pkgs \
    eza \
    bat \
    git-delta || log_warn "Some modern CLI tools not available in apt"

# Create bat symlink (Debian installs as 'batcat')
ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

# lazygit (Git TUI)
log_info "Installing lazygit..."
if ! command_exists lazygit; then
    LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${LAZYGIT_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz" 2>/dev/null | \
            tar xz -C /usr/local/bin lazygit 2>/dev/null && \
            log_success "lazygit ${LAZYGIT_VERSION} installed" || log_warn "lazygit installation failed"
    fi
else
    log_info "lazygit already installed"
fi

# 10. Version managers and prompts
log_info "Installing version managers..."

# fnm (Fast Node Manager — replaces nvm, 10x faster)
if ! command_exists fnm; then
    curl -fsSL https://fnm.vercel.app/install 2>/dev/null | bash -s -- --install-dir "/usr/local/bin" --skip-shell 2>/dev/null || log_warn "fnm installation skipped"
    log_success "fnm installed (Fast Node Manager)"
else
    log_info "fnm already installed"
fi

# Starship prompt (cross-shell, async git/lang info)
if ! command_exists starship; then
    curl -sS https://starship.rs/install.sh 2>/dev/null | sh -s -- --yes 2>/dev/null && \
        log_success "Starship prompt installed" || log_warn "Starship installation failed"
else
    log_info "Starship already installed"
fi

# atuin (shell history with SQLite, replaces CTRL-R)
if ! command_exists atuin; then
    ATUIN_VERSION=$(curl -s https://api.github.com/repos/atuinsh/atuin/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${ATUIN_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/atuinsh/atuin/releases/download/${ATUIN_VERSION}/atuin-x86_64-unknown-linux-gnu.tar.gz" 2>/dev/null | \
            tar xz -C /usr/local/bin --strip-components=1 "atuin-x86_64-unknown-linux-gnu/atuin" 2>/dev/null && \
            log_success "atuin ${ATUIN_VERSION} installed system-wide" || log_warn "atuin installation failed"
    fi
else
    log_info "atuin already installed"
fi

# uv (ultra-fast Python package manager)
if ! command_exists uv; then
    curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | env UV_INSTALL_DIR="/usr/local/bin" sh 2>/dev/null && \
        log_success "uv installed (10-100x faster than pip)" || log_warn "uv installation failed"
else
    log_info "uv already installed"
fi

# 11. CLI utilities
log_info "Installing CLI utilities..."
ensure_pkgs \
    openssl \
    tealdeer

# 12. System profiling tools
log_info "Installing profiling tools..."
ensure_pkgs \
    valgrind \
    iotop \
    nethogs

# 13. Database clients
log_info "Installing database clients..."
ensure_pkgs \
    postgresql-client \
    mariadb-client \
    redis-tools || log_warn "Some database clients not available"

# 14. ActivityWatch for productivity tracking
log_info "Installing ActivityWatch..."
if ! command_exists aw-server; then
    AW_VERSION="v0.12.2"
    AW_URL="https://github.com/ActivityWatch/activitywatch/releases/download/${AW_VERSION}/activitywatch-${AW_VERSION}-linux-x86_64.zip"

    mkdir -p /opt/activitywatch

    if curl -fsSL "$AW_URL" -o /tmp/activitywatch.zip 2>/dev/null; then
        unzip -qo /tmp/activitywatch.zip -d /opt 2>/dev/null || true
        rm -f /tmp/activitywatch.zip
        # Symlink binaries
        for bin in /opt/activitywatch/aw-*/aw-*; do
            [[ -x "$bin" ]] && ln -sf "$bin" /usr/local/bin/"$(basename "$bin")" 2>/dev/null || true
        done
        log_success "ActivityWatch installed to /opt/activitywatch"
    else
        log_warn "ActivityWatch download failed"
    fi
else
    log_info "ActivityWatch already installed"
fi

# Clean up
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

log_section "Development Tools Complete"
log_info "Installed stack:"
log_info "  Docker, kubectl, helm, k9s, kind"
log_info "  Terraform, Ansible"
log_info "  eza, bat, delta, lazygit, btop"
log_info "  starship, atuin, uv, fnm"
log_warn "Post-installation:"
log_warn "  1. Add user to docker group: sudo usermod -aG docker \$USER"
log_warn "  2. Add user to libvirt group: sudo usermod -aG libvirt \$USER"
log_warn "  3. Go bin path: export PATH=\"\$PATH:\$HOME/go/bin\""
