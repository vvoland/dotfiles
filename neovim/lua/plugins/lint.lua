return {
  "mfussenegger/nvim-lint",
  commit = "ae64d6466ed92b68353122d920e314ff2c8dd0a8",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      go = { "golangcilint" },
      yaml = { "yamllint" },
      gha = { "actionlint" },
      bash = { "shellcheck" }
    }

    vim.keymap.set("n", "<leader>ln", function()
      lint.try_lint()
    end, { desc = "Run linter" })

    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function()
        lint.try_lint()
      end,
    })

    lint.try_lint()
  end
}
