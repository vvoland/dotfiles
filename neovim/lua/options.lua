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

vim.api.nvim_create_user_command("Quotes", function(opts)
  local quote = opts.fargs[1] or '"'
  if quote ~= "'" and quote ~= '"' then
    vim.api.nvim_err_writeln('Invalid quote: must be single (\') or double (")')
    return
  end
  local old
  if quote == "\"" then
    old = "'"
  else
    old = '"'
  end
  vim.cmd(string.format("%s/%s/%s/g", '%s', old, quote))
end, {
  nargs = "?",
  complete = function()
    return {"'", '"'}
  end,
  desc = "Replace quotes in buffer with desired quote character (default: \" )"
})

vim.diagnostic.config({
  virtual_text = true,
})

