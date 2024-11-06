vim.cmd([[
    set expandtab
    set shiftwidth=4
    set tabstop=4
    set relativenumber
    set cmdheight=2
    set hidden
    set noshowmode
    set nu
    set mouse=
    set softtabstop=4
    set completeopt=menu,menuone,noselect
    set notermguicolors

    call plug#begin("~/.cache/nvim-plug")
    Plug 'junegunn/fzf.vim'
    Plug 'junegunn/fzf'

    Plug 'dylanaraps/wal.vim'

    Plug 'fatih/go.vim'
    Plug 'rust-lang/rust.vim'
    Plug 'Shougo/echodoc.vim'
    Plug 'neovim/nvim-lspconfig'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/cmp-path'
    Plug 'hrsh7th/cmp-cmdline'
    Plug 'hrsh7th/nvim-cmp'
    Plug 'L3MON4D3/LuaSnip'
    Plug 'hashivim/vim-terraform'
    call plug#end()

    set notermguicolors
    colorscheme wal

    nnoremap <expr> <C-p> (len(system('git rev-parse')) ? ':Files' : ':GFiles --recurse-submodules --exclude-standard --cached')."\<CR>"
    nnoremap <C-b> :call fzf#vim#buffers()<CR>
]])

local nvim_lsp = require('lspconfig')
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
    -- Mappings.
    local opts = { noremap=true, silent=true }
    buf_set_keymap('n', '<leader>gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', '<leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<leader>ga', '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', '<leader>h', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<leader><C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<leader><space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader><space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader><space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<leader><space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<leader><space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<leader><space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '<leader>[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', '<leader>]d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<leader><space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    -- Set some keybinds conditional on server capabilities
    if client.server_capabilities.document_formatting then
        buf_set_keymap("n", "ff", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
    elseif client.server_capabilities.document_range_formatting then
        buf_set_keymap("n", "ff", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
    end
    -- Set autocommands conditional on server_capabilities
    if client.server_capabilities.document_highlight then
        vim.api.nvim_exec([[
        hi LspReferenceRead cterm=bold ctermbg=DarkMagenta guibg=LightYellow
        hi LspReferenceText cterm=bold ctermbg=DarkMagenta guibg=LightYellow
        hi LspReferenceWrite cterm=bold ctermbg=DarkMagenta guibg=LightYellow
        augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
        ]], false)
    end
end
nvim_lsp.gopls.setup{
    cmd = {'gopls'},
    -- for postfix snippets and analyzers
    capabilities = capabilities,
    settings = {
        gopls = {
            experimentalPostfixCompletions = true,
            analyses = {
                unusedparams = true,
                shadow = true,
            },
            staticcheck = true,
        },
    },
    on_attach = on_attach,
}
nvim_lsp.rust_analyzer.setup{
    capabilities = capabilities,
    settings = {
        rust_analyzer = {
        },

    },
    on_attach = on_attach,
}


function goimports(timeoutms)
    local context = { source = { organizeImports = true } }
    vim.validate { context = { context, "t", true } }
    local params = vim.lsp.util.make_range_params()
    params.context = context
    -- See the implementation of the textDocument/codeAction callback
    -- (lua/vim/lsp/handler.lua) for how to do this properly.
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
    if not result or next(result) == nil then return end
    local actions = result[1].result
    if not actions then return end
    local action = actions[1]
    -- textDocument/codeAction can return either Command[] or CodeAction[]. If it
    -- is a CodeAction, it can have either an edit, a command or both. Edits
    -- should be executed first.
    if action.edit or type(action.command) == "table" then
        if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit)
        end
        if type(action.command) == "table" then
            vim.lsp.buf.execute_command(action.command)
        end
    else
        vim.lsp.buf.execute_command(action)
    end
end








local cmp = require('cmp')
local luasnip = require('luasnip')
local select_opts = {behavior = cmp.SelectBehavior.Select}
cmp.setup({
snippet = {
  expand = function(args)
    luasnip.lsp_expand(args.body)
  end
},
sources = {
  {name = 'path'},
  {name = 'nvim_lsp', keyword_length = 3},
  {name = 'buffer', keyword_length = 3},
  {name = 'luasnip', keyword_length = 2},
},
window = {
  documentation = cmp.config.window.bordered()
},
formatting = {
  fields = {'menu', 'abbr', 'kind'},
  format = function(entry, item)
    local menu_icon = {
      nvim_lsp = 'λ',
      luasnip = '⋗',
      buffer = 'Ω',
      path = '🖫',
    }
    item.menu = menu_icon[entry.source.name]
    return item
  end,
},
mapping = {
  ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
  ['<Down>'] = cmp.mapping.select_next_item(select_opts),
  ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
  ['<C-n>'] = cmp.mapping.select_next_item(select_opts),
  ['<C-u>'] = cmp.mapping.scroll_docs(-4),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),
  ['<C-e>'] = cmp.mapping.abort(),
  ['<CR>'] = cmp.mapping.confirm({select = true}),
  ['<C-d>'] = cmp.mapping(function(fallback)
    if luasnip.jumpable(1) then
      luasnip.jump(1)
    else
      fallback()
    end
  end, {'i', 's'}),
  ['<C-b>'] = cmp.mapping(function(fallback)
    if luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end, {'i', 's'}),
  ['<Tab>'] = cmp.mapping(function(fallback)
    local col = vim.fn.col('.') - 1
    if cmp.visible() then
      cmp.select_next_item(select_opts)
    elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
      fallback()
    else
      cmp.complete()
    end
  end, {'i', 's'}),
  ['<S-Tab>'] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_prev_item(select_opts)
    else
      fallback()
    end
  end, {'i', 's'}),
},
})












