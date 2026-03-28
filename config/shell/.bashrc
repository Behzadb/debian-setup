# ~/.bashrc configuration for developer environment
# This file is sourced by interactive bash shells

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# History configuration
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Bash options
shopt -s checkwinsize
shopt -s globstar
shopt -s dotglob

# Prompt - use Starship if available, otherwise fallback
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
elif [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi

# Development environment variables
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Go configuration
if [ -d "$HOME/.go" ]; then
    export GOPATH="$HOME/.go"
    export PATH="$PATH:$GOPATH/bin"
fi

# Node version manager - fnm (Fast Node Manager, replaces nvm)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
elif [ -d "$HOME/.local/share/fnm" ]; then
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
elif [ -d "$HOME/.nvm" ]; then
    # Fallback to nvm if fnm not installed
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
fi

# uv (fast Python package manager) - add to PATH
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# atuin (shell history with SQLite)
if command -v atuin &> /dev/null; then
    eval "$(atuin init bash)"
fi

# Python virtual environment
if [ -d "$HOME/.venv" ]; then
    alias venv='source $HOME/.venv/bin/activate'
fi

# Docker aliases
alias docker-ps='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"'
alias docker-log='docker logs -f'
alias docker-exec='docker exec -it'
alias docker-stop='docker stop'

# Kubernetes aliases
alias k='kubectl'
alias kgs='kubectl get svc'
alias kgp='kubectl get pods'
alias kdp='kubectl describe pod'
alias klog='kubectl logs -f'
alias kex='kubectl exec -it'

# Development aliases
# Use eza if available (modern ls with git status and icons)
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --git --group-directories-first'
    alias la='eza -a --icons'
    alias lt='eza --tree --icons --level=2'
    alias llt='eza --tree --icons -la --level=3'
else
    alias ll='ls -lah'
    alias la='ls -A'
fi
# Use bat if available (syntax-highlighted cat)
if command -v bat &> /dev/null; then
    alias cat='bat --style=numbers,changes,grid'
elif command -v batcat &> /dev/null; then
    alias cat='batcat --style=numbers,changes,grid'
fi
alias grep='grep --color=auto'
alias tmux='tmux -2'
alias nvim='nvim'
alias vim='nvim'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'

# System information and networking aliases
alias myip='curl -s https://api.ipify.org && echo'
alias myip4='curl -s https://ipv4.icanhazip.com'
alias myip6='curl -s https://ipv6.icanhazip.com'
alias listening='ss -tlnp'
alias connections='ss -tnp'
alias ports='netstat -tulanp'
alias fastping='ping -c 100 -i 0.2'
alias ipscan='arp-scan --localnet'
alias ipb='ip -br addr'
alias ipr='ip -br route'
alias disk='df -h | grep -E "^/dev"'
alias mem='free -h'
alias ps='ps aux --sort=-%mem | head -n 20'

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract function for various archive types
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.tar.xz) tar xJf "$1" ;;
            *.zip) unzip "$1" ;;
            *.rar) unrar x "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "Unknown archive type" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

# SSH key management
ssh-add-default() {
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_rsa 2>/dev/null
}

# Load local machine-specific configuration
[ -f ~/.bashrc.local ] && source ~/.bashrc.local
