require("lazy").setup({
  "tomasr/molokai",
  "olimorris/onedarkpro.nvim",
  "Shatur/neovim-ayu",
  "lspcontainers/lspcontainers.nvim",
  "echasnovski/mini.icons",
  { "echasnovski/mini.comment", commit = "871746069a28e35d04a66f88bc0e6831779ccc40" },
  { "ibhagwan/fzf-lua" },
  { "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    }
  },
  "tpope/vim-sleuth",
  "nvim-treesitter/nvim-treesitter",
  "neovim/nvim-lspconfig",
  { "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp" } },
  {
    'jesseleite/nvim-noirbuddy',
    dependencies = {
      { 'tjdevries/colorbuddy.nvim' }
    },
    lazy = false,
    priority = 1000,
  },
  {"hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      { "hrsh7th/cmp-nvim-lua", commit = "f12408bdb54c39c23e67cab726264c10db33ada8" },
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
  },
  {
    "echasnovski/mini.diff",
    config = function()
      local diff = require("mini.diff")
      diff.setup({
        -- Disabled by default
        source = diff.gen_source.none(),
      })
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    lazy = true,
    path = "/dev/shm/codecompanion.nvim",
    opts = {
      adapters = {
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            env = {
              api_key = "cmd: pass show OpenAI",
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "openai",
        },
        inline = {
          adapter = "openai",
        },
        cmd = {
          adapter = "openai",
        },
      },
      log_level = "DEBUG",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
})

require("mini.comment").setup({
  mappings = {
    comment = "<leader>/",
  }
})

require("fzf-lua").setup()

vim.cmd("colorscheme onedark_dark")

-- lualine + noirbuddy
-- local noirbuddy_lualine = require("noirbuddy.plugins.lualine")
require("lualine").setup {
  options = {
    -- theme = "ayu", --noirbuddy_lualine.theme,
    icons_enabled = true,
    filetype = { colored = true },
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = {},
    always_divide_middle = true,
  },
  -- sections = noirbuddy_lualine.sections,
  -- inactive_sections = noirbuddy_lualine.inactive_sections,
}


local map = vim.keymap.set

-- fzf
-- Files
vim.keymap.set("n", "<C-p>", function()
  local git_dir = vim.fn.system("git rev-parse")
  if #git_dir > 0 then
    FzfLua.files()
  else
    FzfLua.git_files()
    -- vim.cmd("GFiles --recurse-submodules --exclude-standard --cached")
  end
end, { expr = false, noremap = true, silent = true })

-- Buffers
vim.keymap.set("n", "<C-b>", function()
  FzfLua.buffers()
end, { noremap = true, silent = true })

-- Lines
vim.keymap.set("n", "<C-l>", function()
  FzfLua.lines()
end, { noremap = true, silent = true })

-- treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "python", "go", "bash", "markdown" },
  highlight = { enable = true },
})

-- lspconfig

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  map("n", "<leader>gd", vim.lsp.buf.definition, opts)
  map("n", "<leader>h", vim.lsp.buf.hover, opts)
  map("n", "<leader>gi", vim.lsp.buf.implementation, opts)
  map("n", "<leader>gr", vim.lsp.buf.references, opts)
  map("n", "<leader>rn", vim.lsp.buf.rename, opts)
  map("n", "<leader><space>", vim.lsp.buf.code_action, opts)
  map("n", "<leader>ff", vim.lsp.buf.format, opts)
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

local lspcontainers = require("lspcontainers")


lspconfig.bashls.setup({
  on_attach = on_attach, capabilities = capabilities
})
lspconfig.pylsp.setup({
  cmd = lspcontainers.command("pylsp"),
  on_attach = on_attach, capabilities = capabilities,
})

lspconfig.html.setup({
  cmd = lspcontainers.command("html"),
  on_attach = on_attach, capabilities = capabilities,
})


-- cmp

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  window = require('noirbuddy.plugins.cmp').window,
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
    { name = "nvim_lua" },
  }),
}
)

-- diagnostics
vim.diagnostic.config({
  virtual_text = true,
})


-- require("ai").setup()

vim.keymap.set({ "n", "v" }, "<leader>ai", function()
  require("codecompanion")
  vim.cmd("CodeCompanion")
end, { noremap = true, silent = true })
