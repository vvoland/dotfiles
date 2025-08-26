return {
  { 
    "olimorris/codecompanion.nvim",
    lazy = true,
    opts = {
      adapters = {
        openai = function()
          local secrets = require("secrets")
          return require("codecompanion.adapters").extend("openai", {
            env = {
              api_key = secrets.pass_func("OpenAI"),
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
