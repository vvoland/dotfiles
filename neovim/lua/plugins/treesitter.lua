return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- Parsers are compiled locally by the tree-sitter CLI.
    if vim.fn.executable("tree-sitter") == 0 then
      vim.notify("nvim-treesitter: tree-sitter CLI not found, skipping parser install", vim.log.levels.WARN)
      return
    end
    require("nvim-treesitter").install({ "pascal", "nix" })
  end,
}
