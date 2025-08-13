require("lazy").setup({
  { "junegunn/fzf.vim",
    dependencies = {
      "junegunn/fzf",
    }
  },
  "nvim-lualine/lualine.nvim",
  "tpope/vim-sleuth",
  "nvim-treesitter/nvim-treesitter",
  "neovim/nvim-lspconfig",
  { "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp" } },
  {
    'jesseleite/nvim-noirbuddy',
    dependencies = {
      { 'tjdevries/colorbuddy.nvim' }
    },
  },
  {"hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
  },
})

require("noirbuddy").setup({
  colors = {
    primary = '#FFE135',
    --primary = '#008080',
  }
})

local map = vim.keymap.set

-- fzf
-- Files
vim.keymap.set('n', '<C-p>', function()
  local git_dir = vim.fn.system('git rev-parse')
  if #git_dir > 0 then
    vim.cmd('Files')
  else
    vim.cmd('GFiles --recurse-submodules --exclude-standard --cached')
  end
end, { expr = false, noremap = true, silent = true })

-- Buffers
vim.keymap.set('n', '<C-b>', function()
  vim.fn['fzf#vim#buffers']()
end, { noremap = true, silent = true })

-- Lines
vim.keymap.set('n', '<C-l>', function()
  vim.fn['fzf#vim#lines']()
end, { noremap = true, silent = true })

-- treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "python", "go", "bash", "markdown" },
  highlight = { enable = true },
})

--vim.api.nvim_create_user_command("Reload", reload, {})

-- lspconfig

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  map("n", "gd", vim.lsp.buf.definition, opts)
  map("n", "<leader>h", vim.lsp.buf.hover, opts)
  map("n", "gi", vim.lsp.buf.implementation, opts)
  map("n", "gr", vim.lsp.buf.references, opts)
  map("n", "<leader>rn", vim.lsp.buf.rename, opts)
  map("n", "<leader><space>", vim.lsp.buf.code_action, opts)
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")

lspconfig.gopls.setup({
  on_attach = on_attach,
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
})


lspconfig.bashls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})


-- cmp

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
        vim.defer_fn(function()
          vim.lsp.buf.signature_help()
        end, 100)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  }),
})
