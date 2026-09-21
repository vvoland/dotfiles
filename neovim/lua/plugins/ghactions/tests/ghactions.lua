-- Run from the plugin directory: nvim --headless -u NONE -i NONE -l tests/ghactions.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local default_gx = vim.fn.maparg("gx", "n", false, true).callback
require("ghactions").setup()
vim.bo.filetype = "yaml"

local opened, notices = {}, {}
vim.ui.open = function(url)
  table.insert(opened, url)
  return { wait = function() return { code = 0 } end }
end
vim.notify = function(message, level)
  table.insert(notices, { message, level })
end

local function eq(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end

local sha = "dbcb813823bdd20940b903addbd779551569679f"
local cases = {
  { "version comment", "        uses: docker/login-action@" .. sha .. " # v4.6.0", "login",
    "https://github.com/docker/login-action/releases/tag/v4.6.0" },
  { "pinned commit", "uses: docker/login-action@" .. sha, "login",
    "https://github.com/docker/login-action/tree/" .. sha },
  { "quoted pin and prerelease", "uses: 'owner/repo@" .. sha .. "' # v1.2.3-rc.1", "repo",
    "https://github.com/owner/repo/releases/tag/v1.2.3-rc.1" },
  { "unprefixed version", 'uses: "owner/repo@main" # 1.2.3  ', "repo",
    "https://github.com/owner/repo/releases/tag/1.2.3" },
  { "release of subdirectory action", "uses: owner/repo/action@main # v1", "action",
    "https://github.com/owner/repo/releases/tag/v1" },
  { "release tag encoding", "uses: owner/repo@main # v1.2.3+build.4", "repo",
    "https://github.com/owner/repo/releases/tag/v1.2.3%2Bbuild.4" },
  { "ordinary comment", "uses: owner/repo@main # pinned version", "repo",
    "https://github.com/owner/repo/tree/main" },
  { "version mentioned in prose", "uses: owner/repo@main # v1.2.3 needs review", "repo",
    "https://github.com/owner/repo/tree/main" },
  { "cursor on SHA", "uses: docker/login-action@" .. sha, sha,
    "https://github.com/docker/login-action/tree/" .. sha },
  { "tag and list item", "  - uses: actions/checkout@v4", "checkout",
    "https://github.com/actions/checkout/tree/v4" },
  { "single quotes", "uses: 'actions/checkout@v4'", "checkout",
    "https://github.com/actions/checkout/tree/v4" },
  { "double quotes", 'uses: "actions/checkout@v4" # comment', "checkout",
    "https://github.com/actions/checkout/tree/v4" },
  { "subdirectory", "uses: owner/repo/path/to/action@v1", "action",
    "https://github.com/owner/repo/tree/v1/path/to/action" },
  { "reusable workflow", "uses: owner/repo/.github/workflows/test.yml@main", "test.yml",
    "https://github.com/owner/repo/tree/main/.github/workflows/test.yml" },
  { "branch with slash", "uses: owner/repo@feature/test", "feature",
    "https://github.com/owner/repo/tree/feature%2Ftest" },
  { "URL encoding", "uses: owner/repo@release%candidate", "release",
    "https://github.com/owner/repo/tree/release%25candidate" },
  { "ordinary URL", "url: https://example.com/page", "example" },
  { "URL in comment", "uses: actions/checkout@v4 # https://example.com", "example" },
  { "local action", "uses: ./local/action", "local" },
  { "container action", "uses: docker://alpine:3", "alpine" },
  { "expression", "uses: ${{ inputs.action }}", "inputs" },
  { "missing ref", "uses: actions/checkout", "checkout" },
  { "unrelated key", "image: owner/repo@v1", "repo" },
  { "commented action", "# uses: actions/checkout@v4", "checkout" },
  { "cursor on key", "uses: actions/checkout@v4", "uses" },
}

for _, case in ipairs(cases) do
  local name, line, cursor, url = unpack(case)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
  vim.api.nvim_win_set_cursor(0, { 1, assert(line:find(cursor, 1, true)) - 1 })
  local expected = { url }
  if not url then
    opened = {}
    default_gx()
    expected = opened
  end
  opened, notices = {}, {}
  vim.cmd("normal gx")
  eq(expected, opened)
  eq({}, notices)
  print("PASS " .. name)
end

local function links(buf)
  buf = buf or 0
  local ready = false
  vim.schedule(function() ready = true end)
  assert(vim.wait(1000, function() return ready end), "Timed out waiting for link updates")
  local result = {}
  local namespace = vim.api.nvim_get_namespaces().GitHubActionsLinks
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })) do
    local row, column, details = mark[2], mark[3], mark[4]
    local text = vim.api.nvim_buf_get_text(buf, row, column, details.end_row, details.end_col, {})
    table.insert(result, { row = row, text = table.concat(text, "\n"), url = details.url })
  end
  return result
end

opened, notices = {}, {}
vim.cmd("enew!")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "# uses: ignored/action@v1",
  "  - uses: 'actions/checkout@v4' # keep quotes and comment outside link",
  "    uses: owner/repo/path/to/action@main",
  "    uses: ./local/action",
  "    uses: docker://alpine:3",
})
vim.bo.filetype = "yaml"
eq({
  { row = 1, text = "actions/checkout@v4", url = "https://github.com/actions/checkout/tree/v4" },
  { row = 2, text = "owner/repo/path/to/action@main", url = "https://github.com/owner/repo/tree/main/path/to/action" },
}, links())
print("PASS terminal links cover only action references when opening YAML")

local old_mouse = vim.o.mouse
for _, ref in ipairs({ "v1", "v2", "main" }) do
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: owner/repo@" .. ref })
  eq({ { row = 0, text = "owner/repo@" .. ref, url = "https://github.com/owner/repo/tree/" .. ref } }, links())
end
eq(old_mouse, vim.o.mouse)
eq({}, opened)
print("PASS terminal links refresh without opening a browser or changing mouse mode")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: ./local/action" })
eq({}, links())
print("PASS editing out a remote action removes its hyperlink")

vim.cmd("filetype on")
local workflows = { ".deploy.yml", "deploy.yml", ".deploy.yaml", "deploy.yaml" }
for _, name in ipairs(workflows) do
  vim.cmd("enew!")
  vim.api.nvim_buf_set_name(0, vim.fn.getcwd() .. "/.github/workflows/" .. name)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: docker/login-action@" .. sha })
  vim.cmd("filetype detect")
  assert(vim.bo.filetype == "yaml" or vim.bo.filetype == "yaml.gha", "Expected a YAML filetype")
  local url = "https://github.com/docker/login-action/tree/" .. sha
  eq({ { row = 0, text = "docker/login-action@" .. sha, url = url } }, links())
  opened = {}
  vim.api.nvim_win_set_cursor(0, { 1, 10 })
  vim.cmd("normal gx")
  eq({ url }, opened)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: docker/login-action@" .. sha .. " # v4.6.0" })
  local release = "https://github.com/docker/login-action/releases/tag/v4.6.0"
  eq({ { row = 0, text = "docker/login-action@" .. sha, url = release } }, links())
  opened = {}
  vim.cmd("normal gx")
  eq({ release }, opened)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: docker/login-action@" .. sha })
  eq({ { row = 0, text = "docker/login-action@" .. sha, url = url } }, links())
  print("PASS detected workflow filetype supports hyperlinks and gx: " .. name)
end

vim.ui.open = function() return nil, "No browser available" end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: actions/checkout@v4" })
vim.api.nvim_win_set_cursor(0, { 1, 10 })
vim.cmd("normal gx")
eq({ { "No browser available", vim.log.levels.ERROR } }, notices)
print("PASS browser launch error")

vim.cmd("enew!")
vim.bo.filetype = "lua"
eq(default_gx, vim.fn.maparg("gx", "n", false, true).callback)
eq({}, links())
print("PASS non-YAML buffers keep default gx")

vim.cmd("enew!")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "uses: a/b@v1", "name: middle", "uses: c/d@main # v2.0.0", "uses: e/f@v3",
})
vim.bo.filetype = "yaml.gha"
vim.api.nvim_buf_set_text(0, 2, 0, 2, #"uses: c/d@main # v2.0.0", { "uses: c/d@main # v2.1.0" })
eq({
  { row = 0, text = "a/b@v1", url = "https://github.com/a/b/tree/v1" },
  { row = 2, text = "c/d@main", url = "https://github.com/c/d/releases/tag/v2.1.0" },
  { row = 3, text = "e/f@v3", url = "https://github.com/e/f/tree/v3" },
}, links())
print("PASS editing a middle line updates its destination and preserves surrounding links")

vim.api.nvim_buf_set_lines(0, 1, 1, false, { "uses: g/h@v4", "name: inserted" })
eq({
  { row = 0, text = "a/b@v1", url = "https://github.com/a/b/tree/v1" },
  { row = 1, text = "g/h@v4", url = "https://github.com/g/h/tree/v4" },
  { row = 4, text = "c/d@main", url = "https://github.com/c/d/releases/tag/v2.1.0" },
  { row = 5, text = "e/f@v3", url = "https://github.com/e/f/tree/v3" },
}, links())
print("PASS inserting lines shifts existing hyperlinks")

vim.api.nvim_buf_set_lines(0, 0, 5, false, {})
eq({ { row = 0, text = "e/f@v3", url = "https://github.com/e/f/tree/v3" } }, links())
vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
eq({}, links())
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "name: first", "uses: a/b@v1" })
vim.api.nvim_buf_set_lines(0, 1, -1, false, {})
eq({}, links())
print("PASS deleting ranges and the last line leaves no stale hyperlinks")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: a/b@v1", "uses: c/d@v2" })
vim.api.nvim_buf_set_text(0, 0, 6, 0, 6, { "", "" })
eq({ { row = 2, text = "c/d@v2", url = "https://github.com/c/d/tree/v2" } }, links())
vim.api.nvim_buf_set_text(0, 0, 6, 1, 0, { "" })
local joined = {
  { row = 0, text = "a/b@v1", url = "https://github.com/a/b/tree/v1" },
  { row = 1, text = "c/d@v2", url = "https://github.com/c/d/tree/v2" },
}
eq(joined, links())
print("PASS splitting and joining an action line refreshes its hyperlink")

vim.api.nvim_buf_set_text(0, 1, #"uses: c/d@v", 1, #"uses: c/d@v2", { "3" })
vim.api.nvim_buf_set_lines(0, 0, 0, false, { "name: prefix", "uses: e/f@v4" })
vim.api.nvim_buf_set_lines(0, 2, 3, false, {})
eq({
  { row = 1, text = "e/f@v4", url = "https://github.com/e/f/tree/v4" },
  { row = 2, text = "c/d@v3", url = "https://github.com/c/d/tree/v3" },
}, links())
print("PASS queued edits track line shifts before the refresh runs")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: a/b@v1", "uses: c/d@v2" })
eq(joined, links())
vim.cmd("let &undolevels = &undolevels")
vim.cmd("normal! ggdd")
local deleted = { { row = 0, text = "c/d@v2", url = "https://github.com/c/d/tree/v2" } }
eq(deleted, links())
vim.cmd("silent undo")
eq(joined, links())
vim.cmd("silent redo")
eq(deleted, links())
print("PASS undo and redo restore the correct hyperlinks without duplicates")

local hidden = vim.api.nvim_get_current_buf()
vim.cmd("hide enew")
vim.api.nvim_buf_set_lines(hidden, 0, -1, false, { "uses: a/b@v1" })
eq({ { row = 0, text = "a/b@v1", url = "https://github.com/a/b/tree/v1" } }, links(hidden))
eq({}, links())
print("PASS changes to a hidden buffer update that buffer only")

local file = vim.fn.tempname() .. ".yaml"
vim.fn.writefile({ "uses: a/b@v1" }, file)
vim.cmd.edit(vim.fn.fnameescape(file))
eq({ { row = 0, text = "a/b@v1", url = "https://github.com/a/b/tree/v1" } }, links())
vim.fn.writefile({ "name: reloaded", "uses: c/d@v2" }, file)
vim.cmd("edit!")
eq({ { row = 1, text = "c/d@v2", url = "https://github.com/c/d/tree/v2" } }, links())
vim.cmd("bdelete")
vim.cmd.edit(vim.fn.fnameescape(file))
vim.api.nvim_buf_set_lines(0, 1, -1, false, { "uses: e/f@v3" })
eq({ { row = 1, text = "e/f@v3", url = "https://github.com/e/f/tree/v3" } }, links())
vim.cmd("bdelete!")
vim.fn.delete(file)
print("PASS reloading and reopening buffers rebuilds working hyperlinks")

vim.ui.open = function(url)
  table.insert(opened, url)
  return { wait = function() return { code = 0 } end }
end

local fallbacks = {
  { "Lua callback", function() vim.g.ghactions_fallback = vim.g.ghactions_fallback + 1 end },
  { "command string", "<Cmd>let g:ghactions_fallback += 1<CR>" },
  { "expression string", [["\<Cmd>let g:ghactions_fallback += 1\<CR>"]],
    { expr = true, replace_keycodes = false } },
  { "expression callback", function() return "<Cmd>let g:ghactions_fallback += 1<CR>" end,
    { expr = true } },
  { "remapped string", "<F6>", { remap = true } },
}
for _, case in ipairs(fallbacks) do
  vim.cmd("enew!")
  vim.g.ghactions_fallback = 0
  vim.keymap.set("n", "<F6>", "<Cmd>let g:ghactions_fallback += 1<CR>", { buffer = true })
  vim.keymap.set("n", "gx", case[2], vim.tbl_extend("force", { buffer = true }, case[3] or {}))
  vim.cmd("normal gx")
  eq(1, vim.g.ghactions_fallback)
  vim.g.ghactions_fallback = 0
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "url: https://example.com", "uses: a/b@v1" })
  vim.bo.filetype = "yaml"
  require("ghactions").setup()
  vim.cmd("doautocmd FileType yaml")
  vim.api.nvim_win_set_cursor(0, { 1, 10 })
  vim.cmd("normal gx")
  eq(1, vim.g.ghactions_fallback)
  opened = {}
  vim.api.nvim_win_set_cursor(0, { 2, 8 })
  vim.cmd("normal gx")
  eq({ "https://github.com/a/b/tree/v1" }, opened)
  eq(1, vim.g.ghactions_fallback)
  print("PASS buffer-local gx fallback: " .. case[1])
end

vim.cmd("enew!")
vim.keymap.set("n", "gx", "<Cmd>let g:ghactions_fallback += 1<CR>")
vim.bo.filetype = "yaml"
vim.g.ghactions_fallback = 0
vim.cmd("normal gx")
eq(1, vim.g.ghactions_fallback)
print("PASS global string gx fallback")

vim.cmd("enew!")
vim.keymap.del("n", "gx")
vim.bo.filetype = "yaml"
opened, notices = {}, {}
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "url: https://example.com" })
vim.cmd("normal gx")
eq({}, opened)
eq({}, notices)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "uses: a/b@v1" })
vim.api.nvim_win_set_cursor(0, { 1, 8 })
vim.cmd("normal gx")
eq({ "https://github.com/a/b/tree/v1" }, opened)
print("PASS absent gx mapping still supports action links")

print(("Passed %d GitHub Actions link tests"):format(#cases + #workflows + 15 + #fallbacks))
vim.cmd("qa!")
