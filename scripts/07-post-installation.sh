#!/bin/bash
# 07-post-installation.sh - Automatic post-installation configuration

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
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

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

# ============================================================================
# Check environment
# ============================================================================

log_section "Post-Installation Setup"

# Detect if running as root
if [ "$EUID" -eq 0 ]; then
    # Running as root - will create user and configure system
    RUNNING_AS_ROOT=1
    log_warn "Running as root - will setup system and create user account"
else
    # Running as regular user - skip user creation, focus on user config
    RUNNING_AS_ROOT=0
    CURRENT_USER="$USER"
    log_info "Running as regular user: $CURRENT_USER"
fi

# ============================================================================
# PHASE 1: User Account Setup (root only)
# ============================================================================

if [ "$RUNNING_AS_ROOT" -eq 1 ]; then
    log_section "Phase 1: User Account Setup"
    
    # Check if we need to create a user
    existing_users=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd | grep -v nobody)
    
    if [ -z "$existing_users" ]; then
        log_info "No regular user account found"
        log_info "Creating default user account..."
        
        # Get username
        read -p "Enter username to create: " NEW_USER
        
        if [ -z "$NEW_USER" ]; then
            log_error "Username cannot be empty"
            exit 1
        fi
        
        if id "$NEW_USER" &>/dev/null; then
            log_warn "User $NEW_USER already exists"
        else
            # Create user with home directory and bash shell
            useradd -m -s /bin/bash "$NEW_USER" || {
                log_error "Failed to create user $NEW_USER"
                exit 1
            }
            log_success "Created user: $NEW_USER"
        fi
        
        CURRENT_USER="$NEW_USER"
    else
        log_info "Found existing user accounts:"
        echo "$existing_users" | while read user; do
            echo "  - $user"
        done
        
        # Use first non-root user
        CURRENT_USER=$(echo "$existing_users" | head -1)
        log_info "Using user: $CURRENT_USER"
    fi
    
    # Add user to sudo group (for passwordless sudo if configured)
    if ! groups "$CURRENT_USER" | grep -q sudo; then
        log_info "Adding $CURRENT_USER to sudo group..."
        usermod -aG sudo "$CURRENT_USER"
        log_success "User added to sudo group"
    else
        log_info "$CURRENT_USER already in sudo group"
    fi
    
    # Add user to docker group (if docker installed)
    if command -v docker &>/dev/null; then
        if ! groups "$CURRENT_USER" | grep -q docker; then
            log_info "Adding $CURRENT_USER to docker group..."
            usermod -aG docker "$CURRENT_USER"
            log_success "User added to docker group"
            log_warn "User must log out and log in for docker group to take effect"
        else
            log_info "$CURRENT_USER already in docker group"
        fi
    fi
    
    # Set home directory variable for later use
    USER_HOME="/home/$CURRENT_USER"
else
    # Running as regular user
    USER_HOME="$HOME"
    log_info "Using home directory: $USER_HOME"
fi

# ============================================================================
# PHASE 2: Shell Configuration (for any user)
# ============================================================================

log_section "Phase 2: Shell Configuration"

# Configure default shell
log_info "Checking shell configuration..."

if [ "$RUNNING_AS_ROOT" -eq 0 ]; then
    # Only suggest shell change if running as user
    current_shell=$(getent passwd "$CURRENT_USER" | cut -d: -f7)
    
    if [ "$current_shell" != "/bin/zsh" ]; then
        log_info "Current shell: $current_shell"
        log_info "Recommended shell: /bin/zsh (more features, better for development)"
        
        # Check if zsh is installed
        if command -v zsh &>/dev/null; then
            read -p "Change default shell to zsh? (y/n): " ans
            if [ "$ans" = "y" ]; then
                chsh -s /bin/zsh "$CURRENT_USER" || {
                    log_warn "Could not change shell (may require password)"
                }
            fi
        fi
    else
        log_info "Shell already set to zsh"
    fi
fi

# ============================================================================
# PHASE 3: SSH Key Setup (for any user)
# ============================================================================

log_section "Phase 3: SSH Key Setup"

SSH_DIR="$USER_HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"

if [ -f "$SSH_KEY" ]; then
    log_info "SSH key already exists: $SSH_KEY"
else
    log_info "Generating SSH key..."
    
    # Create .ssh directory with correct permissions
    if [ "$RUNNING_AS_ROOT" -eq 1 ]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        chown "$CURRENT_USER:$CURRENT_USER" "$SSH_DIR"
    else
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi
    
    # Generate SSH key (non-interactive, no passphrase for automation)
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "Generated by debian-setup" 2>/dev/null || {
        log_warn "SSH key generation failed"
    }
    
    if [ -f "$SSH_KEY" ]; then
        log_success "SSH key generated: $SSH_KEY"
        
        # Fix permissions if running as root
        if [ "$RUNNING_AS_ROOT" -eq 1 ]; then
            chmod 600 "$SSH_KEY"
            chmod 644 "$SSH_KEY.pub"
            chown "$CURRENT_USER:$CURRENT_USER" "$SSH_KEY"*
        fi
        
        log_info "Public key:"
        cat "$SSH_KEY.pub"
        log_info "Add this key to your GitHub/GitLab account at:"
        log_info "  GitHub: https://github.com/settings/keys"
        log_info "  GitLab: https://gitlab.com/-/user_settings/ssh_keys"
    else
        log_warn "Failed to generate SSH key"
    fi
fi

# ============================================================================
# PHASE 4: Git Configuration
# ============================================================================

log_section "Phase 4: Git Configuration"

log_info "Checking Git configuration..."

# Check if git is installed
if ! command -v git &>/dev/null; then
    log_warn "Git is not installed"
else
    # Check if user has git config
    git_user=$(git config --global user.name 2>/dev/null || echo "")
    
    if [ -z "$git_user" ]; then
        log_warn "Git user not configured"
        log_info "Setting up Git global configuration..."
        
        # Use sensible defaults if running automatically
        read -p "Enter Git user name (or press Enter for 'Debian Setup'): " git_name
        git_name="${git_name:-Debian Setup}"
        
        read -p "Enter Git user email (or press Enter for skip): " git_email
        
        if [ -n "$git_email" ]; then
            if [ "$RUNNING_AS_ROOT" -eq 1 ]; then
                # Use su to run as the target user
                su - "$CURRENT_USER" -c "git config --global user.name '$git_name' && git config --global user.email '$git_email'"
                log_success "Git configured for user $CURRENT_USER"
            else
                git config --global user.name "$git_name"
                git config --global user.email "$git_email"
                log_success "Git configured"
            fi
            
            # Also set some useful defaults
            git config --global init.defaultBranch main 2>/dev/null || true
            git config --global pull.rebase false 2>/dev/null || true
        fi
    else
        log_info "Git already configured: $git_user"
    fi
fi

# ============================================================================
# PHASE 5: Vim Plugin Setup
# ============================================================================

log_section "Phase 5: Vim Plugin Manager Setup"

# Install vim-plug
VIM_AUTOLOAD_DIR="$USER_HOME/.vim/autoload"
VIM_PLUG_FILE="$VIM_AUTOLOAD_DIR/plug.vim"

if [ -f "$VIM_PLUG_FILE" ]; then
    log_info "vim-plug already installed"
else
    log_info "Installing vim-plug..."
    
    # Create vim directories
    if [ "$RUNNING_AS_ROOT" -eq 1 ]; then
        mkdir -p "$VIM_AUTOLOAD_DIR"
        chmod 755 "$USER_HOME/.vim"
        chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.vim"
    else
        mkdir -p "$VIM_AUTOLOAD_DIR"
    fi
    
    # Download vim-plug
    curl -fLo "$VIM_PLUG_FILE" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 2>/dev/null || {
        log_warn "Failed to download vim-plug (may need internet)"
    }
    
    if [ -f "$VIM_PLUG_FILE" ]; then
        log_success "vim-plug installed"
        
        if [ "$RUNNING_AS_ROOT" -eq 1 ]; then
            chown "$CURRENT_USER:$CURRENT_USER" "$VIM_PLUG_FILE"
        fi
    else
        log_warn "vim-plug installation failed"
    fi
fi

# ============================================================================
# PHASE 6: Vim Configuration with Plugins
# ============================================================================

log_section "Phase 6: Vim Configuration and Plugins"

VIMRC_PATH="$USER_HOME/.vimrc"

log_info "Checking vim configuration..."

if [ -f "$VIMRC_PATH" ] && grep -q "vim-plug" "$VIMRC_PATH"; then
    log_info "Vim already configured with plugins"
else
    log_info "Creating/updating vim configuration..."
    
    # Create vimrc with essential plugins and settings
    cat > "$VIMRC_PATH" << 'VIMRC_EOF'
" ============================================================================
" VIM Configuration - Auto-generated by debian-setup
" ============================================================================

" Enable vim-plug plugin manager
call plug#begin('~/.vim/plugged')

" === Essential Development Plugins ===

" Syntax highlighting and file detection
Plug 'vim-polyglot'  " Massive language pack

" YAML support (syntax, indentation)
Plug 'stephpy/vim-yaml'

" Dockerfile support
Plug 'ekalinin/Dockerfile.vim'

" Shell script support and linting
Plug 'vim-shellcheck'

" Git integration
Plug 'tpope/vim-fugitive'  " Git commands in vim
Plug 'airblade/vim-gitgutter'  " Show git changes in gutter

" File explorer
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Code completion
Plug 'vim-syntastic/syntastic'  " Syntax checking

" Color schemes
Plug 'morhetz/gruvbox'
Plug 'dracula/vim'

call plug#end()

" ============================================================================
" Basic Settings
" ============================================================================

set nocompatible                " Use Vim settings
set encoding=utf-8              " Use UTF-8 encoding
set number                      " Show line numbers
set relativenumber              " Show relative line numbers
set cursorline                  " Highlight current line
set ruler                       " Show cursor position
set showcmd                     " Show commands being typed

" ============================================================================
" Indentation and Formatting
" ============================================================================

set autoindent                  " Auto indent
set smartindent                 " Smart indentation
set tabstop=4                   " Tab width (display)
set softtabstop=4              " Tab width (editing)
set shiftwidth=4               " Indent width
set expandtab                  " Use spaces instead of tabs
set smarttab                   " Smart tab behavior

" YAML-specific settings (2 spaces)
autocmd FileType yaml setlocal tabstop=2 softtabstop=2 shiftwidth=2

" ============================================================================
" Search and Navigation
" ============================================================================

set ignorecase                  " Ignore case in searches
set smartcase                   " Smart case search
set incsearch                   " Incremental search
set hlsearch                    " Highlight search results
set wildmenu                    " Tab completion in command line

" ============================================================================
" Appearance
" ============================================================================

set background=dark             " Dark background
colorscheme gruvbox            " Use gruvbox color scheme

" Enable syntax highlighting
syntax enable
syntax on

" ============================================================================
" Key Mappings
" ============================================================================

" Map leader key to space
let mapleader = " "

" NERDTree mappings
map <leader>n :NERDTreeToggle<CR>
map <leader>f :NERDTreeFind<CR>

" FZF mappings
map <leader>p :FZF<CR>
map <leader>b :Buffers<CR>
map <leader>g :GFiles<CR>

" Quick save
map <leader>w :w<CR>
map <leader>q :q<CR>

" Navigate splits with arrows
map <leader><Up> :wincmd k<CR>
map <leader><Down> :wincmd j<CR>
map <leader><Left> :wincmd h<CR>
map <leader><Right> :wincmd l<CR>

" ============================================================================
" Plugin Configuration
" ============================================================================

" Airline configuration
let g:airline_theme = 'gruvbox'
let g:airline_powerline_fonts = 1

" Syntastic configuration
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Shell script checking
let g:syntastic_sh_shellcheck_args = "-x"

" ============================================================================
" File Type Specific Settings
" ============================================================================

" Dockerfile
autocmd FileType dockerfile setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Shell scripts
autocmd FileType sh setlocal tabstop=4 softtabstop=4 shiftwidth=4

" JSON
autocmd FileType json setlocal tabstop=2 softtabstop=2 shiftwidth=2

" ============================================================================
" Miscellaneous
" ============================================================================

" Set backspace behavior
set backspace=indent,eol,start

" Always show status line
set laststatus=2

" Disable backup files
set nobackup
set nowritebackup
set noswapfile

" Remember cursor position
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

VIMRC_EOF
    
    if [ "$RUNNING_AS_ROOT" -eq 1 ]; then
        chown "$CURRENT_USER:$CURRENT_USER" "$VIMRC_PATH"
    fi
    
    log_success "Vim configuration created with plugins"
    log_info "Plugins configured:"
    log_info "  - vim-polyglot: Language support"
    log_info "  - vim-yaml: YAML editing with syntax/indentation"
    log_info "  - vim-shellcheck: Shell script linting"
    log_info "  - vim-fugitive: Git integration"
    log_info "  - NERDTree: File explorer"
    log_info "  - FZF: Fuzzy file finder"
    log_info "  - Syntastic: Syntax checking"
    log_info "  - Airline: Status bar"
fi

# ============================================================================
# PHASE 7: Install Plugins (if vim exists)
# ============================================================================

if command -v vim &>/dev/null; then
    log_section "Phase 7: Installing Vim Plugins"
    
    log_info "Running vim-plug :PlugInstall..."
    
    # Install plugins non-interactively
    vim -u "$VIMRC_PATH" +PlugInstall +qall 2>/dev/null || {
        log_warn "Automatic plugin installation had issues"
        log_info "You can manually install by running: vim +PlugInstall +qall"
    }
    
    log_success "Vim plugins installed"
else
    log_warn "vim is not installed - plugins cannot be installed"
fi

# ============================================================================
# Summary
# ============================================================================

log_section "Post-Installation Complete"

echo -e "${GREEN}✓ Configuration Complete!${NC}"
echo ""
echo "What was configured:"
echo "  ✓ User account setup (if needed)"
echo "  ✓ Group memberships (sudo, docker)"
echo "  ✓ SSH key generation"
echo "  ✓ Git configuration"
echo "  ✓ vim-plug plugin manager"
echo "  ✓ Vim plugins installed"
echo ""
echo "Next steps:"
echo "  1. Verify SSH key was added to GitHub/GitLab"
echo "  2. Start vim and verify plugins loaded: vim, then :PlugStatus"
echo "  3. Configure git credentials: git config --global credential.helper store"
echo "  4. Copy your dotfiles to this setup: git clone <your-dotfiles-repo>"
echo "  5. Run dotfiles setup: ./scripts/06-dotfiles.sh"
echo ""
echo "Keyboard shortcuts in Vim:"
echo "  <Space>n  = Toggle file tree (NERDTree)"
echo "  <Space>p  = Fuzzy find files (FZF)"
echo "  <Space>w  = Save file"
echo "  <Space>q  = Quit"
echo ""
log_info "Post-installation script completed at $(date)"

