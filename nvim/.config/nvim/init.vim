"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

function! LatexMode()
    set makeprg=pdflatex\ %
endfunction

" Required:
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  " Let dein manage dein
  " Required:
  call dein#add('~/.cache/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here:
  call dein#add('Shougo/neosnippet.vim')
  call dein#add('Shougo/neosnippet-snippets')
  call dein#add('OmniSharp/omnisharp-vim')
  call dein#add('vim-syntastic/syntastic')
  call dein#add('Shougo/deoplete.nvim')
  call dein#add('roxma/nvim-yarp')
  call dein#add('roxma/vim-hug-neovim-rpc')
  call dein#add('zchee/deoplete-jedi')
  call dein#add('dylanaraps/wal.vim')
  call dein#add('markonm/traces.vim')
  call dein#add('tpope/vim-pathogen')
  call dein#add('editorconfig/editorconfig-vim')
  call dein#add('fsharp/vim-fsharp', { 'on_ft': 'fsharp', 'build': 'make fsautocomplete'})


  " You can specify revision/branch/tag.
  call dein#add('Shougo/deol.nvim', { 'rev': 'a1b5108fd' })

  " Required:
  call dein#end()
  call dein#save_state()
endif


" Required:
filetype plugin indent on

let g:deoplete#enable_at_startup = 1

" If you want to install not installed plugins on startup.
"if dein#check_install()
"  call dein#install()
"endif
"
"
"End dein Scripts-------------------------
"
colorscheme wal

au BufRead /tmp/mutt-* set tw=100


syntax enable
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set clipboard+=unnamedplus
set autowrite
set relativenumber
set rnu
