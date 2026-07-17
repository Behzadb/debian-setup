#!/bin/bash
# 02-development-tools.sh - Development tools, containerization, K8s, and IaC
# SRE-focused toolchain for infrastructure engineering.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

require_root

log_section "Development Tools Installation"

# 0. Prerequisites for adding third-party APT repos (Docker, HashiCorp).
# Normally provided by 00-base-system, but ensure them here so this module is
# safe to run on its own and never emits a malformed sources.list line.
log_info "Ensuring repository prerequisites..."
ensure_pkgs ca-certificates curl gnupg lsb-release

# Resolve the Debian codename once (lsb_release, falling back to os-release).
DEB_CODENAME="$(lsb_release -cs 2>/dev/null || true)"
[[ -z "$DEB_CODENAME" ]] && DEB_CODENAME="$(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}")"
log_info "APT repo codename: ${DEB_CODENAME:-unknown}"

# Architecture tokens for third-party binary downloads. Release assets use one of
# three naming schemes; resolve each once so a non-amd64 host gets the correct
# asset instead of a silently-broken amd64 binary. ARCH_GNU/ARCH_LZ are empty on
# an unsupported arch, and each download below guards on that.
ARCH_DEB="$(get_arch_deb)"                 # amd64 | arm64
case "$(get_arch_gnu)" in
    x86_64)  ARCH_GNU="x86_64";  ARCH_LZ="x86_64" ;;   # ...-x86_64-unknown-linux-gnu
    aarch64) ARCH_GNU="aarch64"; ARCH_LZ="arm64"  ;;   # lazygit/doggo use "arm64" here
    *)       ARCH_GNU="";        ARCH_LZ=""        ;;
esac
log_info "Target architecture: ${ARCH_DEB} (gnu: ${ARCH_GNU:-unsupported})"

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
    if [[ -z "$DEB_CODENAME" ]]; then
        log_warn "Unknown Debian codename — skipping Docker repo. Fallback: apt-get install docker.io"
    else
        # Add Docker GPG key and repository (modern approach)
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | \
            gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $DEB_CODENAME stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Tolerate a failing repo refresh (e.g. release not yet published) instead
        # of aborting the whole module on `set -e`.
        if apt-get update -qq; then
            ensure_pkgs \
                docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin && \
                log_success "Docker installed"
        else
            log_warn "Docker repo update failed — removing repo and trying distro docker.io"
            rm -f /etc/apt/sources.list.d/docker.list
            apt-get update -qq || true
            ensure_pkgs docker.io docker-compose || log_warn "Docker installation failed"
        fi
    fi
else
    log_info "Docker already installed"
fi

# 5. KVM/QEMU virtualization
log_info "Installing KVM and QEMU..."
ensure_pkgs \
    qemu-system-x86 \
    qemu-utils \
    libvirt-daemon \
    libvirt-daemon-system \
    libvirt-clients \
    virtinst \
    virt-manager
# libvirt-daemon-system creates the 'libvirt' group and the libvirtd service that
# 07-post-installation.sh adds the user to — without it those steps are no-ops.

# 6. Vagrant (optional — removed from Debian 13 'main' after its BSL relicense,
# so a missing package must NOT abort this module)
log_info "Installing Vagrant..."
if ! command_exists vagrant; then
    ensure_pkgs vagrant || log_warn "Vagrant unavailable (dropped from Debian 13 main) — install from HashiCorp if needed"
else
    log_info "Vagrant already installed"
fi

# 7. Kubernetes tools
log_info "Installing Kubernetes tools..."

# kubectl
if ! command_exists kubectl; then
    KUBECTL_VERSION=$(curl -fL -s https://dl.k8s.io/release/stable.txt 2>/dev/null)
    if [[ -n "${KUBECTL_VERSION:-}" ]]; then
        kubectl_url="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH_DEB}/kubectl"
        # kubectl publishes a companion .sha256 — verify it (uses the shared helper
        # instead of blindly trusting the download).
        kubectl_sum=$(curl -fsSL "${kubectl_url}.sha256" 2>/dev/null || true)
        if download_and_verify "$kubectl_url" /tmp/kubectl "$kubectl_sum"; then
            install -m 0755 /tmp/kubectl /usr/local/bin/kubectl && rm -f /tmp/kubectl && \
                log_success "kubectl ${KUBECTL_VERSION} installed" || log_warn "kubectl install failed"
        else
            log_warn "kubectl download/verification failed"
        fi
    fi
else
    log_info "kubectl already installed"
fi

# kind (Kubernetes in Docker)
if ! command_exists kind; then
    KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${KIND_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-${ARCH_DEB}" \
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
        curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH_DEB}.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin --strip-components=1 "linux-${ARCH_DEB}/helm" 2>/dev/null && \
        log_success "helm ${HELM_VERSION} installed" || log_warn "helm installation failed"
    fi
else
    log_info "helm already installed"
fi

# k9s (Kubernetes CLI UI)
if ! command_exists k9s; then
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${K9S_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH_DEB}.tar.gz" 2>/dev/null | \
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
        curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_${ARCH_DEB}.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin stern 2>/dev/null && \
        log_success "stern ${STERN_VERSION} installed" || log_warn "stern installation failed"
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
    KUBESTR_VERSION=$(curl -s https://api.github.com/repos/kastenhq/kubestr/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -n "${KUBESTR_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/kastenhq/kubestr/releases/download/${KUBESTR_VERSION}/kubestr_${KUBESTR_VERSION#v}_Linux_${ARCH_DEB}.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin kubestr 2>/dev/null && log_success "kubestr ${KUBESTR_VERSION} installed" || log_warn "kubestr installation failed"
    fi
fi

# ============================================================================
# 8. Infrastructure as Code (IaC) — SRE Essentials
# ============================================================================
log_section "Infrastructure as Code Tools"

# Terraform — try the HashiCorp APT repo first, fall back to the release binary
# (the apt repo may not yet publish the newest Debian codename, e.g. trixie).
log_info "Installing Terraform..."
if ! command_exists terraform; then
    tf_installed=0
    if [[ -n "$DEB_CODENAME" ]]; then
        curl -fsSL https://apt.releases.hashicorp.com/gpg | \
            gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true
        echo "deb [arch=${ARCH_DEB} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $DEB_CODENAME main" | \
            tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        if apt-get update -qq && ensure_pkgs terraform; then
            tf_installed=1
            log_success "Terraform installed from HashiCorp APT repo"
        else
            log_warn "HashiCorp repo has no '$DEB_CODENAME' release — removing repo, using release binary"
            rm -f /etc/apt/sources.list.d/hashicorp.list
            apt-get update -qq || true
        fi
    fi
    if [[ "$tf_installed" -eq 0 ]]; then
        TF_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
        if [[ -n "${TF_VERSION:-}" ]]; then
            curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION#v}/terraform_${TF_VERSION#v}_linux_${ARCH_DEB}.zip" -o /tmp/terraform.zip 2>/dev/null && \
            unzip -qo /tmp/terraform.zip -d /usr/local/bin terraform 2>/dev/null && \
            rm -f /tmp/terraform.zip && \
            log_success "Terraform ${TF_VERSION} installed from release binary" || log_warn "Terraform installation failed"
        fi
    fi
else
    log_info "Terraform already installed: $(terraform version -json 2>/dev/null | head -1 || echo 'version unknown')"
fi

# Ansible
log_info "Installing Ansible..."
ensure_pkgs ansible || {
    log_info "Ansible not in apt — installing via pip..."
    pip3 install --quiet --break-system-packages ansible 2>/dev/null || log_warn "Ansible installation failed"
}

# 8b. Editor: VSCodium (open-source, telemetry-free VS Code) via its APT repo.
# Repo uses a fixed 'vscodium main' suite (no Debian codename → works on any
# release). IMPORTANT: the keyring must be world-readable, otherwise apt's '_apt'
# sandbox user can't verify the signature and the install fails. Don't gate on a
# global `apt-get update` (an unrelated failing repo shouldn't kill VSCodium).
KEYRING=/usr/share/keyrings/vscodium-archive-keyring.gpg
log_info "Installing VSCodium..."
if ! command_exists codium; then
    install -d -m 0755 /usr/share/keyrings
    if curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
         | gpg --dearmor --yes -o "$KEYRING"; then
        chmod a+r "$KEYRING"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://download.vscodium.com/debs vscodium main" \
            | tee /etc/apt/sources.list.d/vscodium.list > /dev/null
        apt-get update -qq || log_warn "apt-get update reported errors (still trying codium)"
        ensure_pkgs codium && log_success "VSCodium installed (launch: codium)" \
            || log_warn "VSCodium install failed — try: sudo apt update && sudo apt install codium"
    else
        log_warn "VSCodium GPG key download failed — skipping (repo not added)"
        rm -f /etc/apt/sources.list.d/vscodium.list
    fi
else
    log_info "VSCodium already installed"
fi

# 9. Productivity tools (modern CLI replacements)
log_info "Installing productivity tools..."
ensure_pkgs \
    tmux \
    neovim \
    ripgrep \
    fd-find \
    jq \
    tree \
    fzf

# Create symlink for fd (Debian installs as 'fdfind')
ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true

# yq — install mikefarah's Go yq from GitHub. NOT the apt 'yq' package, which is a
# different tool (a Python jq-wrapper) with incompatible syntax that most k8s/SRE
# workflows don't expect.
if ! command_exists yq; then
    if curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH_DEB}" \
         -o /usr/local/bin/yq 2>/dev/null; then
        chmod +x /usr/local/bin/yq
        log_success "yq (mikefarah, Go) installed"
    else
        log_warn "yq installation failed"
    fi
else
    log_info "yq already installed"
fi

# Modern CLI tool replacements
log_info "Installing modern CLI tools (eza, bat, delta)..."
ensure_pkgs \
    eza \
    bat \
    git-delta || log_warn "Some modern CLI tools not available in apt"

# Create bat symlink (Debian installs as 'batcat')
ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

# eza is only packaged in Debian 13+ (apt). On Debian 12 the apt install above
# is skipped silently, so fall back to the upstream static binary.
if ! command_exists eza; then
    if [[ -z "$ARCH_GNU" ]]; then
        log_warn "eza: no prebuilt binary for this architecture — skipping"
    else
        log_info "eza not available via apt — installing from GitHub release..."
        curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH_GNU}-unknown-linux-gnu.tar.gz" 2>/dev/null | \
            tar xz -C /usr/local/bin ./eza 2>/dev/null && \
            log_success "eza installed from GitHub release" || log_warn "eza installation failed"
    fi
fi

# lazygit (Git TUI)
log_info "Installing lazygit..."
if ! command_exists lazygit; then
    LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$ARCH_LZ" ]]; then
        log_warn "lazygit: no prebuilt binary for this architecture — skipping"
    elif [[ -n "${LAZYGIT_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_${ARCH_LZ}.tar.gz" 2>/dev/null | \
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
    if [[ -z "$ARCH_GNU" ]]; then
        log_warn "atuin: no prebuilt binary for this architecture — skipping"
    elif [[ -n "${ATUIN_VERSION:-}" ]]; then
        curl -fsSL "https://github.com/atuinsh/atuin/releases/download/${ATUIN_VERSION}/atuin-${ARCH_GNU}-unknown-linux-gnu.tar.gz" 2>/dev/null | \
            tar xz -C /usr/local/bin --strip-components=1 "atuin-${ARCH_GNU}-unknown-linux-gnu/atuin" 2>/dev/null && \
            log_success "atuin ${ATUIN_VERSION} installed system-wide" || log_warn "atuin installation failed"
    fi
else
    log_info "atuin already installed"
fi

# bash-preexec — required for atuin (and Ctrl-R) to work in *bash* (zsh has
# native hooks and doesn't need it). The shell config sources it before atuin.
if [[ ! -f /usr/share/bash-preexec/bash-preexec.sh ]]; then
    mkdir -p /usr/share/bash-preexec
    curl -fsSL "https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh" \
        -o /usr/share/bash-preexec/bash-preexec.sh 2>/dev/null && \
        log_success "bash-preexec installed (enables atuin in bash)" || \
        log_warn "bash-preexec download failed — atuin's bash integration may be limited"
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
ensure_pkgs postgresql-client mariadb-client || log_warn "Some database clients not available"
# Redis was relicensed; Debian 13 ships Valkey (valkey-cli is redis-cli compatible).
# Try redis-tools first (Debian 12), fall back to valkey-tools (Debian 13).
ensure_pkgs redis-tools || ensure_pkgs valkey-tools || log_warn "No Redis/Valkey CLI available"

# 14. ActivityWatch for productivity tracking
log_info "Installing ActivityWatch..."
if command_exists aw-server; then
    log_info "ActivityWatch already installed"
elif [[ "$ARCH_GNU" != "x86_64" ]]; then
    log_warn "ActivityWatch: upstream only ships x86_64 builds — skipping on ${ARCH_GNU:-this arch}"
else
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
