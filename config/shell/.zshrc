# ~/.zshrc configuration for developer environment
# This file is sourced by interactive zsh shells

# Oh-My-Zsh configuration (optional, commented by default)
# export ZSH=$HOME/.oh-my-zsh
# ZSH_THEME="robbyrussell"
# plugins=(git docker kubernetes kubectl)
# source $ZSH/oh-my-zsh.sh

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# Completion
autoload -U compinit && compinit

# Prompt
PROMPT='%n@%m:%~%# '
RPROMPT='%*'

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

# FZF integration (fuzzy finder)
if command -v fzf &> /dev/null; then
    # Enable fzf keybindings
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    
    # fzf keybindings for zsh
    if [ -f ~/.fzf.zsh ]; then
        source ~/.fzf.zsh
    fi
fi

# Python virtual environment
if [ -d "$HOME/.venv" ]; then
    alias venv='source $HOME/.venv/bin/activate'
fi

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias tmux='tmux -2'
alias nvim='nvim'
alias vim='nvim'

# Docker aliases
alias d='docker'
alias dps='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"'
alias dlog='docker logs -f'
alias dex='docker exec -it'
alias dstop='docker stop'
alias dstart='docker start'

# Kubernetes aliases
alias k='kubectl'
alias kgs='kubectl get svc'
alias kgp='kubectl get pods'
alias kdp='kubectl describe pod'
alias klog='kubectl logs -f'
alias kex='kubectl exec -it'
alias kctx='kubectl config current-context'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gl='git log --oneline -n 20'

# System information aliases
alias myip='curl -s https://api.ipify.org && echo'
alias ports='netstat -tulanp'
alias disk='df -h | grep "^/dev"'
alias mem='free -h'
alias top-ps='ps aux --sort=-%mem | head -n 11'

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

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

# Git clone with cd
gcl() {
    git clone "$1" && cd "$(basename "$1" .git)"
}

# Load local machine-specific configuration
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
