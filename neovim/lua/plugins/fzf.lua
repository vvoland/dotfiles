return {
  {
    "ibhagwan/fzf-lua",
    lazy = true,
    keys = {
      -- Files
      {
        "<C-p>",
        function()
          local git_dir = vim.fn.system("git rev-parse")
          if #git_dir > 1 then
            require("fzf-lua").files()
          else
            require("fzf-lua").git_files()
            -- vim.cmd("GFiles --recurse-submodules --exclude-standard --cached")
          end
        end,
        mode = "n",
        desc = "FzfLua Files or Git Files (if in git repo)",
        noremap = true,
        silent = true,
      },
      -- Buffers
      {
        "<C-b>",
        function()
          require("fzf-lua").buffers()
        end,
        mode = "n",
        desc = "FzfLua Buffers",
        noremap = true,
        silent = true,
      },
      -- Lines
      {
        "<C-l>",
        function()
          require("fzf-lua").lines()
        end,
        mode = "n",
        desc = "FzfLua Lines",
        noremap = true,
        silent = true,
      },
    }
  }
}
