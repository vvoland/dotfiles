return {
  { 
    "olimorris/codecompanion.nvim",
    lazy = true,
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
    keys = {
      {
        "<leader>ai",
        "<cmd>CodeCompanion<cr>",
        mode = { "n", "v" },
        desc = "Code Companion",
        noremap = true,
        silent = true,
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
}
