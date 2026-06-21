#!/bin/bash
# update-binaries.sh - Update development binaries from GitHub releases

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# Check if running as root (needed for /usr/local/bin)
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
fi

log_section "Binary Update Checker"

# Function to get latest release version from GitHub
get_latest_release() {
    local repo=$1
    curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/' | head -1
}

# Function to compare versions
version_gt() {
    [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]]
}

# Update kubectl
log_info "Checking kubectl..."
if command -v kubectl &> /dev/null; then
    # `--short` was removed in kubectl 1.28; parse plain --client output instead.
    current_kubectl=$(kubectl version --client 2>/dev/null | grep -oP 'v\K[0-9.]+' | head -1 || echo "unknown")
    latest_kubectl=$(get_latest_release "kubernetes/kubernetes")
    
    log_info "Current kubectl: v$current_kubectl"
    log_info "Latest kubectl:  v$latest_kubectl"
    
    if version_gt "$latest_kubectl" "$current_kubectl"; then
        log_warn "Newer version available. Updating kubectl..."
        curl -LOs "https://dl.k8s.io/release/v${latest_kubectl}/bin/linux/amd64/kubectl" 2>/dev/null && \
        chmod +x kubectl && \
        mv kubectl /usr/local/bin/kubectl && \
        log_info "✓ kubectl updated to v$latest_kubectl"
    else
        log_info "kubectl is up to date"
    fi
else
    log_warn "kubectl not installed"
fi

echo ""

# Update helm
log_info "Checking helm..."
if command -v helm &> /dev/null; then
    current_helm=$(helm version --short 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "unknown")
    latest_helm=$(get_latest_release "helm/helm")
    
    log_info "Current helm: v$current_helm"
    log_info "Latest helm:  v$latest_helm"
    
    if version_gt "$latest_helm" "$current_helm"; then
        log_warn "Newer version available. Updating helm..."
        curl -fsSL "https://get.helm.sh/helm-v${latest_helm}-linux-amd64.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin --strip-components=1 linux-amd64/helm 2>/dev/null && \
        log_info "✓ helm updated to v$latest_helm"
    else
        log_info "helm is up to date"
    fi
else
    log_warn "helm not installed"
fi

echo ""

# Update k9s
log_info "Checking k9s..."
if command -v k9s &> /dev/null; then
    current_k9s=$(k9s version --short 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "unknown")
    latest_k9s=$(get_latest_release "derailed/k9s")
    
    log_info "Current k9s: v$current_k9s"
    log_info "Latest k9s:  v$latest_k9s"
    
    if version_gt "$latest_k9s" "$current_k9s"; then
        log_warn "Newer version available. Updating k9s..."
        curl -fsSL "https://github.com/derailed/k9s/releases/download/v${latest_k9s}/k9s_linux_amd64.tar.gz" 2>/dev/null | \
        tar xz -C /usr/local/bin k9s 2>/dev/null && \
        log_info "✓ k9s updated to v$latest_k9s"
    else
        log_info "k9s is up to date"
    fi
else
    log_warn "k9s not installed"
fi

echo ""

# Update kind
log_info "Checking kind..."
if command -v kind &> /dev/null; then
    current_kind=$(kind version 2>/dev/null | grep -oP 'v\K[0-9.]+' || echo "unknown")
    latest_kind=$(get_latest_release "kubernetes-sigs/kind")
    
    log_info "Current kind: v$current_kind"
    log_info "Latest kind:  v$latest_kind"
    
    if version_gt "$latest_kind" "$current_kind"; then
        log_warn "Newer version available. Updating kind..."
        curl -fsSL "https://github.com/kubernetes-sigs/kind/releases/download/v${latest_kind}/kind-linux-amd64" 2>/dev/null > /usr/local/bin/kind && \
        chmod +x /usr/local/bin/kind && \
        log_info "✓ kind updated to v$latest_kind"
    else
        log_info "kind is up to date"
    fi
else
    log_warn "kind not installed"
fi

echo ""

# Update ActivityWatch
# NOTE: 02-development-tools.sh installs ActivityWatch system-wide to
# /opt/activitywatch and symlinks the binaries into /usr/local/bin, so the
# updater must operate on that same location (not ~/.local/share).
log_info "Checking ActivityWatch..."
AW_DIR="/opt/activitywatch"
if [ -d "$AW_DIR" ]; then
    # The release archive carries no version in its directory names, so read it
    # from the running binary; fall back to "unknown" (forces a refresh).
    current_aw=$(aw-server --version 2>/dev/null | grep -oP 'v?\K[0-9.]+' | head -1 || echo "unknown")
    latest_aw=$(get_latest_release "ActivityWatch/activitywatch")

    log_info "Current ActivityWatch: v$current_aw"
    log_info "Latest ActivityWatch:  v$latest_aw"

    if version_gt "$latest_aw" "$current_aw"; then
        log_warn "Newer version available. Updating ActivityWatch..."
        AW_URL="https://github.com/ActivityWatch/activitywatch/releases/download/v${latest_aw}/activitywatch-v${latest_aw}-linux-x86_64.zip"

        # Backup current installation
        rm -rf "${AW_DIR}.bak"
        cp -a "$AW_DIR" "${AW_DIR}.bak" 2>/dev/null || true

        # Download and extract new version (zip top-level dir is "activitywatch")
        if curl -fsSL "$AW_URL" -o /tmp/activitywatch.zip 2>/dev/null; then
            rm -rf "$AW_DIR"
            unzip -q /tmp/activitywatch.zip -d /opt 2>/dev/null && \
            chmod +x "$AW_DIR"/aw-*/aw-* 2>/dev/null
            # Re-create /usr/local/bin symlinks (matches the installer)
            for bin in "$AW_DIR"/aw-*/aw-*; do
                [ -x "$bin" ] && ln -sf "$bin" /usr/local/bin/"$(basename "$bin")" 2>/dev/null || true
            done
            rm -f /tmp/activitywatch.zip
            log_info "✓ ActivityWatch updated to v$latest_aw"
        else
            log_warn "ActivityWatch download failed, restoring backup"
            [ -d "${AW_DIR}.bak" ] && rm -rf "$AW_DIR" && mv "${AW_DIR}.bak" "$AW_DIR" 2>/dev/null || true
        fi
    else
        log_info "ActivityWatch is up to date"
    fi
else
    log_warn "ActivityWatch not installed"
fi

log_section "Update Check Complete"

log_info "Summary of installed tools:"
echo ""
kubectl version --client 2>/dev/null | head -1 || echo "  kubectl: not installed"
helm version --short 2>/dev/null || echo "  helm: not installed"
k9s version --short 2>/dev/null || echo "  k9s: not installed"
kind version 2>/dev/null || echo "  kind: not installed"
[ -d /opt/activitywatch ] && echo "  ActivityWatch: installed" || echo "  ActivityWatch: not installed"

echo ""
log_info "To schedule automatic updates, add to crontab:"
log_info "  0 0 * * 0 /root/project/debian-setup/scripts/update-binaries.sh >> /var/log/update-binaries.log 2>&1"
log_info "  (Runs weekly on Sunday at midnight)"
