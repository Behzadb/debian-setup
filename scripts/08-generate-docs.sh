#!/bin/bash
# 08-generate-docs.sh - Automated System-Reference.md documentation generator
# Generates a comprehensive markdown reference document with:
#   - Installed packages list
#   - Network configuration (IP, DNS, routes)
#   - i3 keybindings cheat sheet
#   - Installed tool versions
#   - DE tools summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=../setup-helpers.sh
source "$SCRIPT_DIR/../setup-helpers.sh"

OUTPUT_FILE="$REPO_DIR/System-Reference.md"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"

log_section "Generating System-Reference.md"

# ============================================================================
# Helper: safe version getter
# ============================================================================
get_version() {
    local cmd="$1"
    shift
    if command_exists "$cmd"; then
        "$cmd" "$@" 2>/dev/null | head -1 || echo "installed (version unknown)"
    else
        echo "not installed"
    fi
}

# ============================================================================
# Generate the document
# ============================================================================
log_info "Writing documentation to: $OUTPUT_FILE"

cat > "$OUTPUT_FILE" << HEADER
# 🖥️ System Reference — Debian SRE Workstation

> **Auto-generated**: ${TIMESTAMP}
> **Host**: $(hostname -f 2>/dev/null || hostname)
> **Kernel**: $(uname -r)
> **Debian**: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "unknown")

---

HEADER

# ============================================================================
# Section 1: Installed Packages Summary
# ============================================================================
cat >> "$OUTPUT_FILE" << 'SECTION'
## 📦 Installed Packages

### Core SRE & Development Tools

SECTION

{
    echo "| Tool | Version | Purpose |"
    echo "|------|---------|---------|"

    # Docker
    v=$(get_version docker --version)
    echo "| Docker | ${v} | Container runtime |"

    # kubectl
    v=$(get_version kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -1 | awk '{print $2}' || get_version kubectl version --client)
    if command_exists kubectl; then
        v=$(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | head -1 | awk '{print $2}' || echo "installed")
    else
        v="not installed"
    fi
    echo "| kubectl | ${v} | Kubernetes CLI |"

    # Terraform
    v=$(get_version terraform version)
    echo "| Terraform | ${v} | Infrastructure as Code |"

    # Ansible
    v=$(get_version ansible --version)
    echo "| Ansible | ${v} | Configuration management |"

    # Helm
    v=$(get_version helm version --short)
    echo "| Helm | ${v} | Kubernetes package manager |"

    # k9s
    if command_exists k9s; then
        v=$(k9s version --short 2>/dev/null | head -1 || echo "installed")
    else
        v="not installed"
    fi
    echo "| k9s | ${v} | Kubernetes TUI |"

    # kind
    v=$(get_version kind version)
    echo "| kind | ${v} | K8s in Docker |"

    # stern
    v=$(get_version stern --version)
    echo "| stern | ${v} | Multi-pod log tailing |"

    # kustomize
    v=$(get_version kustomize version)
    echo "| kustomize | ${v} | K8s manifest customization |"

    # Git
    v=$(get_version git --version)
    echo "| Git | ${v} | Version control |"

    # Go
    v=$(get_version go version)
    echo "| Go | ${v} | Programming language |"

    # Python
    v=$(get_version python3 --version)
    echo "| Python | ${v} | Programming language |"

    # Node.js
    v=$(get_version node --version)
    echo "| Node.js | ${v} | JavaScript runtime |"

    echo ""
} >> "$OUTPUT_FILE"

# Networking tools
{
    echo "### Network & Diagnostics"
    echo ""
    echo "| Tool | Status | Purpose |"
    echo "|------|--------|---------|"

    for tool_desc in \
        "mtr:Network diagnostic (traceroute + ping)" \
        "trippy:Modern network diagnostic (mtr alternative)" \
        "doggo:Modern DNS lookup (dig alternative)" \
        "tcpdump:Packet capture" \
        "nmap:Network scanner" \
        "tshark:Wireshark CLI" \
        "wireshark:Packet analyzer (GUI)" \
        "iperf3:Network performance testing" \
        "nslookup:DNS lookup" \
        "socat:Network relay/proxy" \
        "certbot:Let's Encrypt certificates" \
        "wg:WireGuard VPN"
    do
        tool="${tool_desc%%:*}"
        desc="${tool_desc#*:}"
        if command_exists "$tool"; then
            echo "| ${tool} | ✅ installed | ${desc} |"
        else
            echo "| ${tool} | ❌ missing | ${desc} |"
        fi
    done

    echo ""
} >> "$OUTPUT_FILE"

# Modern CLI tools
{
    echo "### Modern CLI Replacements"
    echo ""
    echo "| Tool | Replaces | Status |"
    echo "|------|----------|--------|"

    for tool_desc in \
        "eza:ls" \
        "bat:cat" \
        "delta:diff" \
        "btop:htop/top" \
        "fd:find" \
        "ripgrep (rg):grep" \
        "fzf:ctrl-r" \
        "lazygit:git CLI" \
        "atuin:ctrl-r history" \
        "starship:bash/zsh prompt" \
        "uv:pip"
    do
        tool_name="${tool_desc%%:*}"
        tool_cmd="${tool_name%% *}"  # first word
        replaces="${tool_desc#*:}"
        # Handle 'ripgrep (rg)' -> check 'rg'
        [[ "$tool_cmd" == "ripgrep" ]] && tool_cmd="rg"
        if command_exists "$tool_cmd"; then
            echo "| ${tool_name} | ${replaces} | ✅ |"
        else
            echo "| ${tool_name} | ${replaces} | ❌ |"
        fi
    done

    echo ""
} >> "$OUTPUT_FILE"

# ============================================================================
# Section 2: Network Configuration
# ============================================================================
{
    echo "---"
    echo ""
    echo "## 🌐 Network Configuration"
    echo ""

    echo "### IP Addresses"
    echo ""
    echo '```'
    ip -br addr 2>/dev/null || echo "ip command not available"
    echo '```'
    echo ""

    echo "### Default Route"
    echo ""
    echo '```'
    ip route show default 2>/dev/null || echo "no default route"
    echo '```'
    echo ""

    echo "### DNS Resolvers"
    echo ""
    echo '```'
    if [[ -f /etc/resolv.conf ]]; then
        grep -E "^nameserver|^search" /etc/resolv.conf 2>/dev/null || echo "no resolvers configured"
    fi
    echo '```'
    echo ""

    # Show systemd-resolved status if available
    if command_exists resolvectl; then
        echo "### systemd-resolved Status"
        echo ""
        echo '```'
        resolvectl status 2>/dev/null | head -20 || echo "resolvectl not available"
        echo '```'
        echo ""
    fi

    echo "### Public IP"
    echo ""
    public_ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "unavailable")
    echo "- Public IPv4: \`${public_ip}\`"
    echo ""

    echo "### Firewall (UFW)"
    echo ""
    echo '```'
    ufw status verbose 2>/dev/null || echo "UFW not configured"
    echo '```'
    echo ""
} >> "$OUTPUT_FILE"

# ============================================================================
# Section 3: i3 Keybindings Cheat Sheet
# ============================================================================
{
    echo "---"
    echo ""
    echo "## ⌨️ i3 Keybindings Cheat Sheet"
    echo ""
    echo "> Parsed from \`~/.config/i3/config\` — \`\$mod\` = Super (Windows) key"
    echo ""

    I3_CONFIG="${REPO_DIR}/config/i3/config"
    if [[ -f "$I3_CONFIG" ]]; then
        echo "| Keybinding | Action |"
        echo "|------------|--------|"

        # Parse bindsym lines from i3 config
        grep -E "^bindsym" "$I3_CONFIG" 2>/dev/null | \
            sed 's/bindsym \$mod+/Super+/g' | \
            sed 's/bindsym //' | \
            while IFS= read -r line; do
                # Split on first space after the key combo
                key=$(echo "$line" | awk '{print $1}')
                action=$(echo "$line" | cut -d' ' -f2-)
                # Clean up action for readability
                action=$(echo "$action" | sed 's/exec --no-startup-id /run: /g' | sed 's/exec /run: /g')
                echo "| \`${key}\` | ${action} |"
            done

        echo ""
    else
        echo "*i3 config not found at ${I3_CONFIG}*"
        echo ""
        echo "Default essential keybindings:"
        echo ""
        echo "| Keybinding | Action |"
        echo "|------------|--------|"
        echo "| \`Super+Enter\` | Open terminal |"
        echo "| \`Super+d\` | Application launcher (rofi) |"
        echo "| \`Super+Shift+q\` | Close window |"
        echo "| \`Super+1-9\` | Switch workspace |"
        echo "| \`Super+Shift+1-9\` | Move window to workspace |"
        echo "| \`Super+h/j/k/l\` | Navigate windows |"
        echo "| \`Super+Shift+e\` | Exit i3 |"
        echo "| \`Super+Shift+r\` | Restart i3 |"
        echo ""
    fi

} >> "$OUTPUT_FILE"

# ============================================================================
# Section 4: Desktop Environment Summary
# ============================================================================
{
    echo "---"
    echo ""
    echo "## 🎨 Desktop Environment"
    echo ""
    echo "| Component | Tool | Notes |"
    echo "|-----------|------|-------|"
    echo "| Window Manager | i3 | Tiling, keyboard-driven |"
    echo "| Status Bar | Polybar | Catppuccin Mocha themed |"
    echo "| Terminal | Kitty | GPU-accelerated, ligatures |"
    echo "| Launcher | Rofi | App launcher + window switcher |"
    echo "| Notifications | Dunst | Catppuccin themed |"
    echo "| Compositor | Picom | Transparency + blur |"
    echo "| Lock Screen | betterlockscreen | Blurred wallpaper + Catppuccin ring |"
    echo "| File Manager | Thunar | GTK file manager |"
    echo "| Screenshot | Flameshot | Region select + annotation |"
    echo "| Clipboard | CopyQ | Persistent clipboard history |"
    echo "| Monitor | btop | CPU/RAM/Disk/Network graphs |"
    echo "| Theme | Catppuccin Mocha | Dark, warm, consistent |"
    echo "| Icons | Papirus-Dark | Modern, crisp icons |"
    echo "| Font | FiraCode Nerd Font | Ligatures + 10k+ icons |"
    echo "| Prompt | Starship | Cross-shell, async git info |"
    echo ""

} >> "$OUTPUT_FILE"

# ============================================================================
# Section 5: Quick Reference Commands
# ============================================================================
{
    echo "---"
    echo ""
    echo "## 🚀 Quick Reference"
    echo ""
    echo "### System"
    echo '```bash'
    echo "btop                      # System monitor"
    echo "sensors                   # CPU temperature"
    echo "sudo tlp-stat -p          # Power/TLP status"
    echo "sudo lynis audit system   # Security audit"
    echo '```'
    echo ""
    echo "### Docker & Kubernetes"
    echo '```bash'
    echo "docker run hello-world    # Test Docker"
    echo "kind create cluster       # Local K8s cluster"
    echo "k9s                       # K8s TUI dashboard"
    echo "kubectl get pods -A       # List all pods"
    echo '```'
    echo ""
    echo "### Networking"
    echo '```bash'
    echo "myip                      # Public IP"
    echo "mtr 8.8.8.8              # Network diagnostic"
    echo "listening                  # Show listening ports"
    echo "sudo tcpdump -i any       # Packet capture"
    echo "sudo nmap -sn 192.168.1.0/24  # LAN scan"
    echo '```'
    echo ""
    echo "### Git & Development"
    echo '```bash'
    echo "lazygit                   # Git TUI"
    echo "bat file.py               # Syntax-highlighted cat"
    echo "eza -la --icons --git     # Modern ls"
    echo "fd pattern                # Modern find"
    echo "rg pattern                # Modern grep"
    echo '```'
    echo ""
    echo "---"
    echo ""
    echo "*Generated by [debian-setup](https://github.com/Behzadb/debian-setup) at ${TIMESTAMP}*"

} >> "$OUTPUT_FILE"

log_success "System-Reference.md generated: $OUTPUT_FILE"
log_info "Lines: $(wc -l < "$OUTPUT_FILE") | Size: $(du -h "$OUTPUT_FILE" | awk '{print $1}')"
