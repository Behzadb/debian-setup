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

# Completion (zsh-native; bashcompinit lets tools that only ship bash-style
# completions work in zsh too). atuin/zsh need no preexec helper — zsh has hooks.
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p "$ZSH_CACHE_DIR"
autoload -Uz compinit && compinit -d "$ZSH_CACHE_DIR/zcompdump"
autoload -Uz bashcompinit && bashcompinit

# Rich completion behaviour: arrow-key menu, case-insensitive + partial-word
# matching, ls-style colours, grouped results, and on-disk caching (faster).
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"
zstyle ':completion:*' rehash true          # find newly-installed binaries without restart
setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END AUTO_CD

# Prompt - use Starship if available
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
else
    PROMPT='%n@%m:%~%# '
    RPROMPT='%*'
fi

# Development environment variables
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Go: add the module bin dir to PATH (GOPATH defaults to ~/go, not ~/.go)
if command -v go &> /dev/null; then
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$PATH:$GOPATH/bin"
fi

# Node version manager - fnm (Fast Node Manager, replaces nvm)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
elif [ -d "$HOME/.local/share/fnm" ]; then
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
elif [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
fi

# User-local binaries (pip --user, `uv tool` installs, pipx, etc.)
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Rust / cargo binaries
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# FZF integration (fuzzy finder). Sourced BEFORE atuin so atuin keeps Ctrl-R —
# fzf's key-bindings also grab Ctrl-R and whichever loads last wins.
if command -v fzf &> /dev/null; then
    command -v fd &> /dev/null && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND:-}"
    for _f in /usr/share/doc/fzf/examples/key-bindings.zsh \
              /usr/share/doc/fzf/examples/completion.zsh \
              ~/.fzf.zsh; do
        [ -f "$_f" ] && source "$_f"
    done
    unset _f
fi

# atuin (shell history — owns Ctrl-R: TUI with exit codes, duration, directory)
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# Python virtual environment
if [ -d "$HOME/.venv" ]; then
    alias venv='source $HOME/.venv/bin/activate'
fi

# Aliases
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

# System information and networking aliases
alias myip='curl -s https://api.ipify.org && echo'
alias myip4='curl -s https://ipv4.icanhazip.com'
alias myip6='curl -s https://ipv6.icanhazip.com'
alias listening='ss -tlnp'
alias connections='ss -tnp'
alias ports='ss -tulpn'
alias fastping='ping -c 100 -i 0.2'
alias ipscan='arp-scan --localnet'
alias ipb='ip -br addr'
alias ipr='ip -br route'
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
