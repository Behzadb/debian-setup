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

# Programmable completion (git, docker, systemctl, apt, kubectl, …).
# This custom .bashrc replaces Debian's default, so we must enable it ourselves.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Completion behaviour — the defaults feel "basic"; these readline tweaks make
# Tab-completion rich (case-insensitive, single-Tab listing, colours, cycling).
# They normally live in ~/.inputrc; set here so this .bashrc is self-contained.
if [[ $- == *i* ]]; then
    bind 'set completion-ignore-case on'        # Tab ignores case (Foo == foo)
    bind 'set completion-map-case on'           # treat - and _ as equivalent
    bind 'set show-all-if-ambiguous on'         # one Tab lists matches (no double-Tab)
    bind 'set show-all-if-unmodified on'
    bind 'set colored-stats on'                 # colour the list by file type (like ls)
    bind 'set colored-completion-prefix on'     # highlight the part you've typed
    bind 'set mark-symlinked-directories on'    # add / after symlinked dirs
    bind 'set visible-stats on'                 # show file-type indicators
    bind 'set menu-complete-display-prefix on'
    bind 'set completion-query-items 200'
    bind 'set page-completions off'
    bind '"\e[Z": menu-complete-backward'       # Shift-Tab cycles matches backwards
fi

# Directory navigation niceties
shopt -s autocd 2>/dev/null     # type a dir name to cd into it
shopt -s cdspell                # auto-correct minor typos in `cd` paths
shopt -s dirspell               # auto-correct dir typos during completion
shopt -s direxpand              # expand ~, $VARs and globs on Tab

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
    # Fallback to nvm if fnm not installed
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
    for _f in /usr/share/doc/fzf/examples/key-bindings.bash \
              /usr/share/bash-completion/completions/fzf \
              ~/.fzf.bash; do
        [ -f "$_f" ] && source "$_f"
    done
    unset _f
fi

# atuin (shell history — owns Ctrl-R: TUI with exit codes, duration, directory)
# In bash, atuin REQUIRES bash-preexec to hook command recording / Ctrl-R, so
# source it first (installed by scripts/02-development-tools.sh).
if command -v atuin &> /dev/null; then
    for _bp in /usr/share/bash-preexec/bash-preexec.sh ~/.local/share/bash-preexec.sh; do
        [ -f "$_bp" ] && source "$_bp" && break
    done
    unset _bp
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
alias ports='ss -tulpn'
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
