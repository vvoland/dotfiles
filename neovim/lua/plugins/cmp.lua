return {
  {"hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      { "hrsh7th/cmp-nvim-lua", commit = "f12408bdb54c39c23e67cab726264c10db33ada8" },
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      { "onsails/lspkind.nvim", commit = "d79a1c3299ad0ef94e255d045bed9fa26025dab6" },
    },
    opts = {
      window = {
        completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          col_offset = 0,
          side_padding = 0,
        },
      },
      formatting = {
        fields = { "menu", "abbr", "kind" },
        format = function(entry, vim_item)
          return require("lspkind").cmp_format({
            mode = "text_symbol",
            -- maxwidth = {
            --   -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            --   -- can also be a function to dynamically calculate max width such as
            --   -- menu = function() return math.floor(0.45 * vim.o.columns) end,
            --   menu = 50, -- leading text (labelDetails)
            --   abbr = 50, -- actual suggestion item
            -- },
            -- ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
            show_labelDetails = true, -- show labelDetails in menu. Disabled by default
          })(entry, vim_item)
        end,
      },
    },
  },
}
