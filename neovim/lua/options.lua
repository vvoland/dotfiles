vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.hidden = true
vim.opt.clipboard:append("unnamedplus")
vim.opt.mouse = ""
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.termguicolors = true
vim.g.mapleader = "\\"

vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = {"*.mdx"},
    command = "set filetype=markdown"
})

vim.diagnostic.config({
  virtual_text = true,
})

