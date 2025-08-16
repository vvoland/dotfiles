-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("options")
require("lazy").setup("plugins")

require("fzf-lua").setup()

-- lualine + noirbuddy
-- local noirbuddy_lualine = require("noirbuddy.plugins.lualine")
require("lualine").setup {
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
}


local map = vim.keymap.set

-- fzf
-- Files
vim.keymap.set("n", "<C-p>", function()
  local git_dir = vim.fn.system("git rev-parse")
  if #git_dir > 0 then
    FzfLua.files()
  else
    FzfLua.git_files()
    -- vim.cmd("GFiles --recurse-submodules --exclude-standard --cached")
  end
end, { expr = false, noremap = true, silent = true })

-- Buffers
vim.keymap.set("n", "<C-b>", function()
  FzfLua.buffers()
end, { noremap = true, silent = true })

-- Lines
vim.keymap.set("n", "<C-l>", function()
  FzfLua.lines()
end, { noremap = true, silent = true })

-- treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "python", "go", "bash", "markdown" },
  highlight = { enable = true },
})

-- lspconfig

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  map("n", "<leader>gd", vim.lsp.buf.definition, opts)
  map("n", "<leader>h", vim.lsp.buf.hover, opts)
  map("n", "<leader>gi", vim.lsp.buf.implementation, opts)
  map("n", "<leader>gr", vim.lsp.buf.references, opts)
  map("n", "<leader>rn", vim.lsp.buf.rename, opts)
  map("n", "<leader><space>", vim.lsp.buf.code_action, opts)
  map("n", "<leader>ff", vim.lsp.buf.format, opts)
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")

lspconfig.gopls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    gopls = {
      experimentalPostfixCompletions = true,
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
    },
  },
})

local lspcontainers = require("lspcontainers")


lspconfig.jsonls.setup({
  on_attach = on_attach, capabilities = capabilities
})
lspconfig.html.setup({
  on_attach = on_attach, capabilities = capabilities
})
lspconfig.bashls.setup({
  on_attach = on_attach, capabilities = capabilities
})
lspconfig.pylsp.setup({
  cmd = lspcontainers.command("pylsp"),
  on_attach = on_attach, capabilities = capabilities,
})


lspconfig.yamlls.setup {
  before_init = function(params)
    params.processId = vim.NIL
  end,
  cmd = lspcontainers.command("yamlls"),
  image = "quay.io/redhat-developer/yaml-language-server:latest",
  root_dir = require("lspconfig/util").root_pattern(".git", vim.fn.getcwd()),
}


-- cmp

local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
        vim.defer_fn(function()
          vim.lsp.buf.signature_help()
        end, 100)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
    { name = "nvim_lua" },
  }),
}
)

-- diagnostics
vim.diagnostic.config({
  virtual_text = true,
})


-- require("ai").setup()

vim.keymap.set({ "n", "v" }, "<leader>ai", function()
  require("codecompanion")
  vim.cmd("CodeCompanion")
end, { noremap = true, silent = true })
