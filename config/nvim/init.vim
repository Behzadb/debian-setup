" ~/.config/nvim/init.vim — make Neovim reuse the shared ~/.vimrc.
"
" The shell defaults to nvim (EDITOR=nvim, `vim` is aliased to nvim) but the
" editor configuration (vim-plug + NERDTree/ALE/airline/Catppuccin) is generated
" as ~/.vimrc by scripts/07-post-installation.sh. Without this shim Neovim would
" ignore that config entirely. Pointing Neovim's runtimepath at ~/.vim and
" sourcing ~/.vimrc reuses the exact same plugins (installed under ~/.vim/plugged
" via vim-plug at ~/.vim/autoload/plug.vim) — no separate plugin set to maintain.

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

if filereadable(expand('~/.vimrc'))
  source ~/.vimrc
endif
