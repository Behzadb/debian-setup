#!/bin/bash
# setup-helpers.sh - Shared utility library for all setup scripts
# Source this at the top of every script: source "$(dirname "${BASH_SOURCE[0]}")/setup-helpers.sh"
# or from scripts/: source "$(dirname "${BASH_SOURCE[0]}")/../setup-helpers.sh"

set -euo pipefail

# ============================================================================
# Color Definitions
# ============================================================================
readonly _CLR_RED='\033[0;31m'
readonly _CLR_GREEN='\033[0;32m'
readonly _CLR_YELLOW='\033[1;33m'
readonly _CLR_BLUE='\033[0;34m'
readonly _CLR_CYAN='\033[0;36m'
readonly _CLR_MAGENTA='\033[0;35m'
readonly _CLR_NC='\033[0m'

# ============================================================================
# Logging Functions (color-coded, timestamped, optional tee to LOG_FILE)
# ============================================================================
_log() {
    local level_color="$1" level_tag="$2"
    shift 2
    local timestamp
    timestamp="$(date '+%H:%M:%S')"
    local msg="${level_color}[${timestamp}] [${level_tag}]${_CLR_NC} $*"
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo -e "$msg" | tee -a "$LOG_FILE"
    else
        echo -e "$msg"
    fi
}

log_info()    { _log "$_CLR_GREEN"   "INFO"    "$@"; }
log_warn()    { _log "$_CLR_YELLOW"  "WARN"    "$@"; }
log_error()   { _log "$_CLR_RED"     "ERROR"   "$@"; }
log_success() { _log "$_CLR_GREEN"   "  ✓ "    "$@"; }
log_debug()   { [[ "${DEBUG:-0}" == "1" ]] && _log "$_CLR_CYAN" "DEBUG" "$@" || true; }

log_section() {
    local msg="$1"
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo -e "\n${_CLR_BLUE}════════════════════════════════════════${_CLR_NC}" | tee -a "$LOG_FILE"
        echo -e "${_CLR_BLUE}  ${msg}${_CLR_NC}" | tee -a "$LOG_FILE"
        echo -e "${_CLR_BLUE}════════════════════════════════════════${_CLR_NC}\n" | tee -a "$LOG_FILE"
    else
        echo -e "\n${_CLR_BLUE}════════════════════════════════════════${_CLR_NC}"
        echo -e "${_CLR_BLUE}  ${msg}${_CLR_NC}"
        echo -e "${_CLR_BLUE}════════════════════════════════════════${_CLR_NC}\n"
    fi
}

# ============================================================================
# Pre-flight Guards
# ============================================================================

# Check if running as root
require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log_error "This script must be run as root (use: sudo ./setup.sh)"
        exit 1
    fi
}

# ============================================================================
# Package Management Helpers (idempotent)
# ============================================================================

# Check if a package is already installed via dpkg
pkg_installed() {
    dpkg -s "$1" &>/dev/null
}

# Check if a group exists
group_exists() {
    getent group "$1" &>/dev/null
}

# Install a list of packages, skipping any already installed.
# Usage: ensure_pkgs pkg1 pkg2 pkg3 ...
ensure_pkgs() {
    local to_install=()
    for pkg in "$@"; do
        if ! pkg_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_debug "All packages already installed: $*"
        return 0
    fi

    log_info "Installing ${#to_install[@]} package(s): ${to_install[*]}"
    wait_for_apt_lock
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" || {
        log_warn "Some packages may have failed: ${to_install[*]}"
        return 1
    }
}

# Wait for any other apt/dpkg processes to finish before proceeding.
wait_for_apt_lock() {
    local waited=0
    local lock_files=("/var/lib/dpkg/lock-frontend" "/var/lib/apt/lists/lock" "/var/lib/dpkg/lock")
    
    for lock in "${lock_files[@]}"; do
        while fuser "$lock" &>/dev/null 2>&1; do
            if [[ $waited -eq 0 ]]; then
                log_warn "Waiting for other apt/dpkg processes to finish ($lock)..."
            fi
            sleep 2
            waited=$((waited + 1))
            if [[ $waited -gt 60 ]]; then
                log_error "Timed out waiting for apt lock after 120 seconds"
                return 1
            fi
        done
    done
}

# ============================================================================
# General Utility Functions
# ============================================================================

# Check if a command exists on PATH
command_exists() {
    command -v "$1" &>/dev/null
}

# Backup file before modification (idempotent — won't backup symlinks)
backup_file() {
    local file="$1"
    if [[ -f "$file" && ! -L "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp -a "$file" "$backup"
        log_info "Backed up: $file → $backup"
        echo "$backup"
    fi
}

# Append content to a file only if it's not already present (idempotent)
append_if_missing() {
    local file="$1"
    local marker="$2"  # grep pattern to check
    local content="$3" # content to append

    if ! grep -qF "$marker" "$file" 2>/dev/null; then
        echo "$content" >> "$file"
        log_info "Appended config to $file"
    else
        log_debug "Config already present in $file"
    fi
}

# Retry a command up to N times with a delay
retry() {
    local max_attempts="${1:-3}"
    local delay="${2:-5}"
    shift 2
    local attempt=1

    while true; do
        "$@" && return 0 || {
            if [[ $attempt -ge $max_attempts ]]; then
                log_error "Command failed after $max_attempts attempts: $*"
                return 1
            fi
            log_warn "Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..."
            sleep "$delay"
            attempt=$((attempt + 1))
        }
    done
}

# ============================================================================
# Secure Downloads
# ============================================================================

# Download a file and optionally verify its checksum
# Usage: download_and_verify URL FILE [CHECKSUM]
download_and_verify() {
    local url="$1"
    local file="$2"
    local expected_checksum="${3:-}"

    log_info "Downloading $url..."
    curl -fsSL "$url" -o "$file" || {
        log_error "Failed to download $url"
        return 1
    }

    if [[ -n "$expected_checksum" ]]; then
        log_info "Verifying checksum for $file..."
        local actual_checksum
        actual_checksum=$(sha256sum "$file" | awk '{print $1}')
        if [[ "$actual_checksum" != "$expected_checksum" ]]; then
            log_error "Checksum verification failed for $file!"
            log_error "Expected: $expected_checksum"
            log_error "Actual:   $actual_checksum"
            rm -f "$file"
            return 1
        fi
        log_success "Checksum verified for $file"
    fi
    return 0
}

# ============================================================================
# Systemd Service Helpers
# ============================================================================
enable_service() {
    local service="$1"
    systemctl enable "$service" >/dev/null 2>&1 && \
        log_success "Enabled service: $service" || \
        log_warn "Could not enable service: $service"
}

start_service() {
    local service="$1"
    systemctl start "$service" >/dev/null 2>&1 && \
        log_success "Started service: $service" || \
        log_warn "Could not start service: $service"
}

restart_service() {
    local service="$1"
    systemctl restart "$service" >/dev/null 2>&1 && \
        log_success "Restarted service: $service" || \
        log_warn "Could not restart service: $service"
}

# ============================================================================
# Desktop/UI Helpers
# ============================================================================

# Install a Nerd Font
install_nerd_font() {
    local font_name="$1"
    local font_zip_name="$2"
    local font_dir="/usr/local/share/fonts/NerdFonts"
    
    mkdir -p "$font_dir"
    if ! fc-list | grep -qi "${font_name} Nerd"; then
        log_info "Installing ${font_name} Nerd Font..."
        local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_zip_name}.zip"
        if curl -fsSL "$url" -o "/tmp/${font_zip_name}.zip" 2>/dev/null; then
            unzip -qo "/tmp/${font_zip_name}.zip" -d "$font_dir" '*.ttf' 2>/dev/null || true
            rm -f "/tmp/${font_zip_name}.zip"
            fc-cache -fv "$font_dir" > /dev/null 2>&1
            log_success "${font_name} Nerd Font installed"
        else
            log_warn "${font_name} Nerd Font download failed"
        fi
    else
        log_success "${font_name} Nerd Font already installed"
    fi
}

# ============================================================================
# System Detection
# ============================================================================
get_debian_version() {
    grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || echo "unknown"
}

get_cpu_vendor() {
    if grep -q "GenuineIntel" /proc/cpuinfo 2>/dev/null; then
        echo "intel"
    elif grep -q "AuthenticAMD" /proc/cpuinfo 2>/dev/null; then
        echo "amd"
    else
        echo "unknown"
    fi
}

get_total_memory_gb() {
    awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo
}

detect_system() {
    log_section "System Detection"
    log_info "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    log_info "Kernel: $(uname -r)"
    log_info "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
    log_info "CPU Vendor: $(get_cpu_vendor)"
    log_info "Memory: $(get_total_memory_gb)GB"
    log_info "Disk (/home): $(df -h /home | awk 'NR==2 {print $4}') available"
}

# ============================================================================
# Error Handling Trap
# ============================================================================
_error_handler() {
    local line="${1:-unknown}"
    local script="${BASH_SOURCE[1]:-unknown}"
    log_error "Script failed at ${script}:${line}"
    log_error "Last command failed with exit code $?"
    if [[ -n "${LOG_FILE:-}" ]]; then
        log_error "Check full log file for details: $LOG_FILE"
    fi
    exit 1
}

# Enable error trap
# The main setup.sh sets this; sub-scripts inherit it.
