return {
  "saghen/blink.cmp",
  commit = "bae4bae0eedd1fa55f34b685862e94a222d5c6f8",
  dependencies = {
    { "rafamadriz/friendly-snippets", commit = "572f5660cf05f8cd8834e096d7b4c921ba18e175" },
  },

  ---@module "blink.cmp"
  ---@type blink.cmp.Config
  opts = {
    -- "default" (recommended) for mappings similar to built-in completions (C-y to accept)
    -- "super-tab" for mappings similar to vscode (tab to accept)
    -- "enter" for enter to accept
    -- "none" for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = {
      preset = "super-tab",
      -- ["<C-l>"] = {
      --   function(cmp)
      --     cmp.show { providers = { "minuet" } }
      --   end,
      -- },
    },

    signature = {
      enabled = true,
    },

    completion = {
      documentation = { auto_show = false },
      menu = { auto_show = true },
      ghost_text = {
        enabled = true,
        show_with_menu = true,
      },
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        minuet = {
          name = "minuet",
          module = "minuet.blink",
          async = true,
          -- Should match minuet.config.request_timeout * 1000,
          -- since minuet.config.request_timeout is in seconds
          timeout_ms = 9000,
          score_offset = 50, -- Gives minuet higher priority among suggestions
        },
      },
    },
    fuzzy = { implementation = "lua" }
  },
  opts_extend = { "sources.default" }
}
