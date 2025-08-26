local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  local map = vim.keymap.set
  map("n", "<leader>gd", vim.lsp.buf.definition, opts)
  map("n", "<leader>h", vim.lsp.buf.hover, opts)
  map("n", "<leader>gi", vim.lsp.buf.implementation, opts)
  map("n", "<leader>gr", vim.lsp.buf.references, opts)
  map("n", "<leader>rn", vim.lsp.buf.rename, opts)
  map("n", "<leader><space>", vim.lsp.buf.code_action, opts)
  map("n", "<leader>ff", function()
    vim.lsp.buf.format()
    vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
  end, opts)
end

local lspconfig = require("lspconfig")

lspconfig.gopls.setup({
  on_attach = on_attach,
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
  on_attach = on_attach,
})
lspconfig.html.setup({
  on_attach = on_attach,
})
lspconfig.bashls.setup({
  on_attach = on_attach,
})
lspconfig.pylsp.setup({
  cmd = lspcontainers.command("pylsp"),
  on_attach = on_attach,
})

local util = require("lspconfig/util")

lspconfig.yamlls.setup {
  before_init = function(params)
    params.processId = vim.NIL
  end,
  cmd = lspcontainers.command("yamlls"),
  image = "quay.io/redhat-developer/yaml-language-server:latest",
  root_dir = util.root_pattern(".git", vim.fn.getcwd()),
}
