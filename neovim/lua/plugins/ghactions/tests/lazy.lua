-- Run from the plugin directory with LAZY_NVIM_PATH pointing to a lazy.nvim checkout.
-- nvim --headless -u NONE -i NONE -l tests/lazy.lua
local lazy_path = assert(vim.env.LAZY_NVIM_PATH, "Set LAZY_NVIM_PATH to a lazy.nvim checkout")
vim.opt.loadplugins = true
vim.opt.runtimepath:prepend(lazy_path)
require("lazy").setup({
  {
    dir = vim.fn.getcwd(),
    ft = { "yaml", "yaml.gha" },
    main = "ghactions",
    opts = {},
  },
}, {
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false },
})

vim.bo.filetype = "lua"
assert(not package.loaded.ghactions, "Plugin loaded before a YAML buffer")
print("PASS plugin stays unloaded for non-YAML buffers")

local opened = {}
vim.ui.open = function(url)
  table.insert(opened, url)
  return { wait = function() return { code = 0 } end }
end

local first = vim.env.GHACTIONS_TEST_FILETYPE or "yaml"
for _, filetype in ipairs({ first, first == "yaml" and "yaml.gha" or "yaml" }) do
  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: actions/checkout@v4" })
  vim.bo.filetype = filetype
  local namespace = assert(vim.api.nvim_get_namespaces().GitHubActionsLinks)
  local marks = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, { details = true })
  assert(#marks == 1, "Expected one hyperlink after loading " .. filetype)
  assert(marks[1][4].url == "https://github.com/actions/checkout/tree/v4")
  vim.api.nvim_win_set_cursor(0, { 1, 10 })
  vim.cmd("normal gx")
  assert(opened[#opened] == "https://github.com/actions/checkout/tree/v4")
  print("PASS lazy-loaded hyperlinks and gx in " .. filetype)
end
assert(#opened == 2, "Expected one browser call per gx")
vim.cmd("qa!")
