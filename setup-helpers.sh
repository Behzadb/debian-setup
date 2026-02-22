#!/bin/bash
# setup-helpers.sh - Utility functions for setup scripts

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo ""
}

# Check if running as root
require_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This requires root privileges"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install package if not exists (idempotent)
install_if_missing() {
    local package=$1
    if ! command_exists "$package"; then
        log_info "Installing $package..."
        apt-get install -y -qq "$package"
        log_success "$package installed"
    else
        log_warn "$package already installed"
    fi
}

# Backup file before modification
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        local backup="${file}.bak.$(date +%s)"
        cp "$file" "$backup"
        log_info "Backed up: $backup"
        echo "$backup"
    fi
}

# Check internet connectivity
check_connectivity() {
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_success "Internet connectivity OK"
        return 0
    else
        log_warn "No internet connectivity detected"
        return 1
    fi
}

# Get total available disk space in GB
get_disk_space() {
    df /home | awk 'NR==2 {print int($4/1024/1024)}'
}

# Check minimum disk space requirement
check_disk_space() {
    local required_gb=${1:-10}
    local available=$(get_disk_space)
    
    if [ "$available" -lt "$required_gb" ]; then
        log_error "Insufficient disk space: ${available}GB available, ${required_gb}GB required"
        return 1
    else
        log_success "Disk space OK: ${available}GB available"
        return 0
    fi
}

# Wait for apt lock
wait_for_apt() {
    while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        log_warn "Waiting for other apt processes to finish..."
        sleep 1
    done
}

# Retry function (useful for flaky network operations)
retry() {
    local n=1
    local max=5
    local delay=5
    
    while true; do
        "$@" && break || {
            if [ $n -lt $max ]; then
                echo "Command failed. Attempt $n/$max. Retrying in ${delay}s..."
                sleep $delay
                ((n++))
            else
                log_error "Command failed after $max attempts"
                return 1
            fi
        }
    done
}

# Systemd service helper
enable_service() {
    local service=$1
    systemctl enable "$service" > /dev/null 2>&1 && \
    log_success "Enabled service: $service"
}

start_service() {
    local service=$1
    systemctl start "$service" > /dev/null 2>&1 && \
    log_success "Started service: $service"
}

restart_service() {
    local service=$1
    systemctl restart "$service" > /dev/null 2>&1 && \
    log_success "Restarted service: $service"
}

# Check if file contains string (idempotent config update)
file_contains() {
    grep -q "$1" "$2" 2>/dev/null
}

# Append to file if not exists (idempotent)
append_if_missing() {
    local file=$1
    local content=$2
    
    if ! file_contains "$content" "$file"; then
        echo "$content" >> "$file"
        log_info "Added to $file: $content"
    fi
}

# Get CPU info
get_cpu_info() {
    grep -E "vendor_id|model name" /proc/cpuinfo | head -2
}

# Get memory info in GB
get_total_memory() {
    awk '/MemTotal/ {print int($2/1024/1024) "GB"}' /proc/meminfo
}

# Detect system information
detect_system() {
    log_section "System Detection"
    
    log_info "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    log_info "Kernel: $(uname -r)"
    log_info "CPU: $(get_cpu_info | tail -1 | cut -d':' -f2 | xargs)"
    log_info "Memory: $(get_total_memory)"
    log_info "Disk: $(get_disk_space)GB available"
    
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        log_info "CPU Type: Intel"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        log_info "CPU Type: AMD"
    fi
}

# Progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' '-'
    printf "] %d%%\n" "$percentage"
}

# Export functions for sourcing
export -f log_info log_warn log_error log_debug log_success log_section
export -f require_root command_exists install_if_missing backup_file
export -f check_connectivity get_disk_space check_disk_space
export -f retry enable_service start_service restart_service
export -f file_contains append_if_missing detect_system
