#!/bin/bash
# 06-dotfiles.sh - Chezmoi Configuration Manager

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_section() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

log_section "Dotfiles Setup (Chezmoi)"

if [ "$EUID" -eq 0 ]; then
    log_warn "Running as root - dotfiles will be applied to /root"
fi

if ! command -v chezmoi &> /dev/null; then
    log_info "Installing chezmoi..."
    if command -v curl &> /dev/null; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
    else
        apt-get update -qq && apt-get install -y -qq chezmoi 2>/dev/null || true
    fi
    log_success "Chezmoi installed"
else
    log_success "Chezmoi already installed"
fi

log_info "Applying dotfiles natively from local repository..."
# Using --source to directly apply from the current debian-setup repo
chezmoi --source "$REPO_DIR" apply

log_success "Dotfiles installed intuitively via chezmoi!"
