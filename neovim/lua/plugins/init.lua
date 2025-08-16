return {
  { "folke/lazy.nvim", commit = "6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a" },
  "lspcontainers/lspcontainers.nvim",
  { "echasnovski/mini.icons", commit = "b8f6fa6f5a3fd0c56936252edcd691184e5aac0c" },
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
  -- {
  --   'jesseleite/nvim-noirbuddy',
  --   dependencies = {
  --     { 'tjdevries/colorbuddy.nvim' }
  --   },
  --   lazy = false,
  --   priority = 1000,
  -- },
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
        chat = { adapter = "openai", },
        inline = { adapter = "openai", },
        cmd = { adapter = "openai", },
      },
      log_level = "DEBUG",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
}

