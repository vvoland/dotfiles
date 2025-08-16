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
      -- sections = noirbuddy_lualine.sections,
      -- inactive_sections = noirbuddy_lualine.inactive_sections,
    },
}
}
