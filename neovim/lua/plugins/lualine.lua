return {
  { "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      options = {
        -- theme = "ayu", --noirbuddy_lualine.theme,
        icons_enabled = true,
        filetype = { colored = true },
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {},
        always_divide_middle = true,
      },
      sections = {
        lualine_a = {"mode"},
        lualine_b = {"branch", "diff", "diagnostics"},
        lualine_c = {
          {
            "filename",
            path = 3, -- Show the full file path
          }
        },
        lualine_x = {"lsp_status", "encoding", "fileformat", "filetype"},
        lualine_y = {"progress"},
        lualine_z = {"location"},
      },
    },
  }
}
