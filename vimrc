set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=4
set clipboard+=unnamedplus
set nu
set relativenumber
set rnu

call plug#begin('~/.cache/vim-plugged')
Plug 'junegunn/fzf.vim'
Plug 'dylanaraps/wal.vim'
call plug#end()


set hidden
"set signcolumn=yes
set cmdheight=2
set noshowmode

filetype plugin on

nnoremap <expr> <C-p> (len(system('git rev-parse')) ? ':Files' : ':GFiles --recurse-submodules --exclude-standard --cached')."\<CR>"
nnoremap <C-b> :call fzf#vim#buffers()<CR>


colorscheme wal
