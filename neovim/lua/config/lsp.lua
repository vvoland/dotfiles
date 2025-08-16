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
