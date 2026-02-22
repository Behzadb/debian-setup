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

# Prompt configuration
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # Color support
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    # Fallback
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

# Node version manager
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
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
alias ll='ls -lah'
alias la='ls -A'
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

# System information aliases
alias myip='curl -s https://api.ipify.org && echo'
alias ports='netstat -tulanp'
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
