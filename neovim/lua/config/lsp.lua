vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp-keymap", { clear = true }),
  callback = function(ev)
    local bufnr = ev.buf
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
      vim.lsp.buf.code_action({
        context = { only = { "source.organizeImports" } },
        apply = true,
      })
    end, opts)
  end,
})

local lspcontainers = require("lspcontainers")

vim.lsp.config("gopls", {
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

vim.lsp.config("pylsp", {
  cmd = lspcontainers.command("pylsp"),
})

vim.lsp.config("yamlls", {
  before_init = function(params)
    params.processId = vim.NIL
  end,
  cmd = lspcontainers.command("yamlls", {
    image = "quay.io/redhat-developer/yaml-language-server:latest",
  }),
  -- root_markers = { ".git" },
})

vim.lsp.enable("gopls")
vim.lsp.enable("jsonls")
vim.lsp.enable("html")
vim.lsp.enable("bashls")
vim.lsp.enable("pylsp")
vim.lsp.enable("terraformls")
vim.lsp.enable("yamlls")
