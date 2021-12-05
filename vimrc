set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=4
set clipboard+=unnamedplus
set relativenumber
set nu

call plug#begin('~/.cache/vim-plugged')
Plug 'junegunn/fzf.vim'
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }
Plug 'Shougo/echodoc.vim'
Plug 'Shougo/deoplete.nvim'
Plug 'roxma/nvim-yarp'
Plug 'roxma/vim-hug-neovim-rpc'
Plug 'dylanaraps/wal.vim'
call plug#end()


set hidden
"set signcolumn=yes
set cmdheight=2
set noshowmode
set completeopt-=preview

filetype plugin on

let g:deoplete#enable_at_startup = 1
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'popup'

set omnifunc=LanguageClient#complete

let g:LanguageClient_serverCommands = {
    \ 'go': ['~/go/bin/gopls'],
    \ 'cpp': ['~/.local/bin/ccls'],
    \ 'c': ['~/.local/bin/ccls'],
    \ 'python': ['/usr/local/bin/pyls'],
    \ }

augroup LSP
    autocmd!
	nnoremap <leader>gd :call LanguageClient#textDocument_definition()<CR>
	nnoremap <leader>lr :call LanguageClient#textDocument_rename()<CR>
	nnoremap <leader>lf :call LanguageClient#textDocument_formatting()<CR>
	nnoremap <leader>lt :call LanguageClient#textDocument_typeDefinition()<CR>
	nnoremap <leader>lx :call LanguageClient#textDocument_references()<CR>
	nnoremap <leader>la :call LanguageClient_workspace_applyEdit()<CR>
	nnoremap <leader>lc :call LanguageClient#textDocument_completion()<CR>
	nnoremap <leader>lh :call LanguageClient#textDocument_hover()<CR>
	nnoremap <leader>ls :call LanguageClient_textDocument_documentSymbol()<CR>
	nnoremap <leader>lm :call LanguageClient_contextMenu()<CR>
augroup END


colorscheme wal
set notermguicolors
highlight Search ctermfg=0
