return {
  { "tomasr/molokai", commit = "c67bdfcdb31415aa0ade7f8c003261700a885476" },
  { "olimorris/onedarkpro.nvim", commit = "3891f6f8db49774aa861d08ddc7c18ad8f1340e9",
    config = function(opts)
      vim.cmd("colorscheme onedark_dark")
    end,
    priority = 1000,
    lazy = false,
  },
  { "Shatur/neovim-ayu", commit = "8f236d3d65cf55bf0664aefd850c326580152270" },
  -- {
  --   'jesseleite/nvim-noirbuddy',
  --   dependencies = {
  --     { 'tjdevries/colorbuddy.nvim' }
  --   },
  --   lazy = false,
  --   priority = 1000,
  -- },
}
