set nocompatible

call plug#begin('~/.cache/vim-plugged')
    Plug 'roxma/nvim-yarp'
    Plug 'roxma/vim-hug-neovim-rpc'
    Plug 'stephpy/vim-yaml'
    Plug 'markonm/traces.vim'
    Plug 'editorconfig/editorconfig-vim'
    Plug 'rust-lang/rust.vim'
    Plug 'peterhoeg/vim-qml'

    Plug 'autozimu/LanguageClient-neovim', { 'do': 'bash install.sh'}

    Plug 'Shougo/echodoc.vim'

    Plug 'dylanaraps/wal.vim'
    Plug 'NLKNguyen/papercolor-theme'
    Plug 'rakr/vim-one'

    Plug 'junegunn/fzf', { 'dir': '~/.cache/fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'

    Plug 'OmniSharp/omnisharp-vim'
    Plug 'ncm2/ncm2'
    Plug 'ncm2/ncm2-path'
    Plug 'ncm2/ncm2-cssomni'
    Plug 'ncm2/ncm2-jedi'
    Plug 'leafgarland/typescript-vim'
    Plug 'CaffeineViking/vim-glsl'
call plug#end()

"source /usr/share/doc/fzf/examples/fzf.vim
nnoremap <expr> <C-p> (len(system('git rev-parse')) ? ':Files' : ':GFiles --recurse-submodules --exclude-standard --cached')."\<cr>"
nnoremap <C-b> :call fzf#vim#buffers()<cr>

command! -bang -nargs=* Rg call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case ".shellescape(<q-args>), 1, {'options': '--delimiter : --nth 4..'}, <bang>0)

let g:LanguageClient_serverCommands = {
\ 'rust': ['rust-analyzer'],
\ 'cpp': ['ccls', '--log-file=/tmp/cq.log'],
\ 'c': ['ccls', '--log-file=/tmp/cq.log'],
\ 'typescript': ['typescript-language-server', '--stdio'],
\ 'python': ['pyls'],
\ }

set completefunc=LanguageClient#complete
set completeopt=noinsert,menuone,noselect
set formatexpr=LanguageClient_textDocument_rangeFormatting()

augroup LSP
  nnoremap <leader>gd :call LanguageClient#textDocument_definition()<CR>
  nnoremap <leader>gt :call LanguageClient#textDocument_typeDefinition()<CR>
  nnoremap <leader>gr :call LanguageClient#textDocument_references()<CR>

  nnoremap <leader>s :call LanguageClient_textDocument_documentSymbol()<CR>
  nnoremap <leader>r :call LanguageClient#textDocument_rename()<CR>
  nnoremap <leader>f :call LanguageClient#textDocument_formatting()<CR>
  nnoremap <leader>h :call LanguageClient#textDocument_hover()<CR>
  nnoremap <leader><Space> :call LanguageClient_contextMenu()<CR>
  noremap <C-\> <ESC>:call LanguageClient_contextMenu()<CR>

  "nnoremap <leader><Space> :call LanguageClient#textDocument_completion()<CR>
augroup END

noremap <C-k> <ESC>:.w !pkill espeak; espeak --stdin -s 160 -k10 --punct &<CR><CR>

autocmd BufEnter * call ncm2#enable_for_buffer()

augroup OmniSharp
  autocmd!
  let g:OmniSharp_server_stdio = 1
  let g:OmniSharp_selector_ui = 'fzf'
  let g:OmniSharp_highlight_types = 0
  let g:omnicomplete_fetch_full_documentation = 1
  let g:OmniSharp_diagnostic_overrides = {
    \ 'IDE0010': {'type': 'I'},
    \ 'IDE0055': {'type': 'W', 'subtype': 'Style'},
    \ 'CS8019': {'type': 'None'},
    \ 'RemoveUnnecessaryImportsFixable': {'type': 'None'}
    \}

  set previewheight=5
  let g:syntastic_cs_checkers = ['code_checker']

  " Show type information automatically when the cursor stops moving.
  " Note that the type is echoed to the Vim command line, and will overwrite
  " any other messages in this space including e.g. ALE linting messages.
  autocmd CursorHold *.cs OmniSharpTypeLookup

  autocmd FileType cs command! -bang -nargs=* Rg call fzf#vim#grep("rg -g '*.cs' --column --line-number --no-heading --color=always --smart-case ".shellescape(<q-args>), 1, {'options': '--delimiter : --nth 4..'}, <bang>0)
  autocmd FileType cs let $FZF_DEFAULT_COMMAND = 'find . -type f -iname "*.cs"'

  " The following commands are contextual, based on the cursor position.
  autocmd FileType cs nmap <silent> <buffer> <Leader>gd <Plug>(omnisharp_go_to_definition)
  autocmd FileType cs nmap <silent> <buffer> <Leader>fu <Plug>(omnisharp_find_usages)
  autocmd FileType cs nmap <silent> <buffer> <Leader>fi <Plug>(omnisharp_find_implementations)
  autocmd FileType cs nmap <silent> <buffer> <Leader>pd <Plug>(omnisharp_preview_definition)
  autocmd FileType cs nmap <silent> <buffer> <Leader>pi <Plug>(omnisharp_preview_implementations)
  autocmd FileType cs nmap <silent> <buffer> <Leader>tt <Plug>(omnisharp_type_lookup)
  autocmd FileType cs nmap <silent> <buffer> <Leader>osd <Plug>(omnisharp_documentation)
  autocmd FileType cs nmap <silent> <buffer> <Leader>fs <Plug>(omnisharp_find_symbol)
  autocmd FileType cs nmap <silent> <buffer> <Leader>osu <Plug>(omnisharp_fix_usings)

  " Find all code errors/warnings for the current solution and populate the quickfix window
  autocmd FileType cs nmap <silent> <buffer> <Leader>osgcc <Plug>(omnisharp_global_code_check)
  " Contextual code actions (uses fzf, CtrlP or unite.vim selector when available)
  autocmd FileType cs nmap <silent> <buffer> <Leader><Space> <Plug>(omnisharp_code_actions)
  autocmd FileType cs xmap <silent> <buffer> <Leader><Space> <Plug>(omnisharp_code_actions)

  autocmd FileType cs nmap <silent> <buffer> <Leader>osf <Plug>(omnisharp_code_format)

  autocmd FileType cs nmap <silent> <buffer> <Leader>rr <Plug>(omnisharp_rename)

  autocmd FileType cs nmap <silent> <buffer> <Leader>osre <Plug>(omnisharp_restart_server)
  autocmd FileType cs nmap <silent> <buffer> <Leader>osst <Plug>(omnisharp_start_server)
  autocmd FileType cs nmap <silent> <buffer> <Leader>ossp <Plug>(omnisharp_stop_server)
augroup END



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
"colorscheme wal
set background=dark
let g:PaperColor_Theme_Options = {
  \   'theme': {
  \     'default': {
  \       'transparent_background': 1
  \     }
  \   }
  \ }
colorscheme PaperColor

au BufRead /tmp/mutt-* set tw=100

let g:netrw_banner=0
let g:netrw_winsize=13
let g:netrw_browse_split=4
let g:netrw_altv=1

set cmdheight=2
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'signature'


syntax enable
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set clipboard+=unnamedplus
set autowrite
set relativenumber
set nu rnu
set path+=**

set modeline
set modelines=5

