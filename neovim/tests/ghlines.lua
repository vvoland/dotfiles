-- Run from this config directory: nvim --headless -u NONE -l tests/ghlines.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
require("ghlines").setup()
local real_notify = vim.notify
local real_clipboard = vim.g.clipboard
local notices, copied = {}, nil
vim.g.clipboard = {
  name = "GHLines test",
  copy = { ["+"] = function(lines) copied = lines end, ["*"] = function() end },
  paste = { ["+"] = function() return { {}, "v" } end, ["*"] = function() return { {}, "v" } end },
}
vim.notify = function(message, level)
  table.insert(notices, { message = message, level = level })
end
local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. "/nested dir", "p")
local path = "nested dir/café #%.lua"
vim.fn.writefile({ "first", "second", "third" }, dir .. "/" .. path)
local function git(...)
  local argv = { "git", "-C", dir }
  vim.list_extend(argv, { ... })
  local result = vim.system(argv, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout or "")
end
local function eq(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local passed = 0
local function test(name, fn)
  notices, copied = {}, nil
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    vim.fn.delete(dir, "rf")
    vim.cmd("cquit 1")
  end
  passed = passed + 1
  print("PASS " .. name)
end
local function failure(fragment)
  local last = assert(notices[#notices])
  eq(vim.log.levels.ERROR, last.level)
  assert(last.message:find(fragment, 1, true), last.message)
  eq(nil, copied)
end

git("init", "-q")
git("add", "--", path)
git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "-c", "commit.gpgsign=false",
  "commit", "-qm", "fixture")
git("remote", "add", "origin", "git@github.com:owner/repo.git")
local commit = git("rev-parse", "HEAD")
local base = "https://github.com/owner/repo/blob/" .. commit .. "/nested%20dir/caf%C3%A9%20%23%25.lua"
vim.cmd.edit(vim.fn.fnameescape(dir .. "/" .. path))
local buf = vim.api.nvim_get_current_buf()
local cwd = vim.fn.getcwd()
local function link(command, anchor, level)
  vim.cmd(command)
  eq(base .. anchor, vim.fn.getreg('"'))
  eq({ base .. anchor }, copied)
  local last = assert(notices[#notices])
  assert(last.message:find(base .. anchor, 1, true), last.message)
  eq(level or vim.log.levels.INFO, last.level)
  eq(cwd, vim.fn.getcwd())
end

test("current line, encoded nested path and clipboard outside repo cwd", function()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  link("GHLines", "#L2")
end)
test("explicit range and single line", function()
  link("1,3GHLines", "#L1-L3")
  link("1GHLines", "#L1")
end)
for _, mode in ipairs({ "v", "V", "\22" }) do
  test("visual selection " .. vim.inspect(mode), function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd.normal({ args = { mode .. "j\27" }, bang = true })
    link("'<,'>GHLines", "#L1-L2")
  end)
end
for _, remote in ipairs({ "https://github.com/owner/repo.git", "https://github.com/owner/repo",
  "ssh://git@github.com/owner/repo.git", "ssh://git@github.com:22/owner/repo.git" }) do
  test("remote " .. remote, function()
    git("remote", "set-url", "origin", remote)
    link("1GHLines", "#L1")
  end)
end
test("detached HEAD still uses immutable commit", function()
  git("checkout", "--detach", "-q", commit)
  link("1GHLines", "#L1")
end)
test("no clipboard provider keeps the URL in the unnamed register", function()
  local real_has = vim.fn.has
  vim.fn.has = function(feature)
    if feature == "clipboard" then return 0 end
    return real_has(feature)
  end
  vim.cmd("1GHLines")
  vim.fn.has = real_has
  eq(base .. "#L1", vim.fn.getreg('"'))
  eq(nil, copied)
  assert(notices[#notices].message:find("unnamed register", 1, true))
end)
test("unsaved edits warn without saving", function()
  vim.api.nvim_buf_set_lines(0, 0, 1, false, { "unsaved" })
  link("1GHLines", "#L1", vim.log.levels.WARN)
  assert(notices[#notices].message:find("Local edits", 1, true))
  eq("first", vim.fn.readfile(dir .. "/" .. path)[1])
  vim.api.nvim_buf_set_lines(0, 0, 1, false, { "first" })
  vim.bo.modified = false
end)
test("saved and staged edits warn", function()
  vim.fn.writefile({ "changed", "second", "third" }, dir .. "/" .. path)
  link("1GHLines", "#L1", vim.log.levels.WARN)
  git("add", "--", path)
  link("1GHLines", "#L1", vim.log.levels.WARN)
end)
test("non-GitHub origin is rejected", function()
  git("remote", "set-url", "origin", "git@example.invalid:owner/repo.git")
  vim.cmd("GHLines")
  failure("not a supported GitHub remote")
end)
test("missing origin is reported", function()
  git("remote", "remove", "origin")
  vim.cmd("GHLines")
  failure("remote get-url origin")
end)
test("untracked file is rejected", function()
  local untracked = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(untracked)
  vim.api.nvim_buf_set_name(untracked, dir .. "/untracked.lua")
  vim.cmd("GHLines")
  failure("cat-file")
end)
test("unnamed buffer is rejected", function()
  vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
  vim.cmd("GHLines")
  failure("local, committed file")
end)
test("special buffer is rejected", function()
  vim.api.nvim_set_current_buf(buf)
  vim.bo.buftype = "nofile"
  vim.cmd("GHLines")
  failure("local, committed file")
  vim.bo.buftype = ""
end)
test("directory outside a repository is rejected", function()
  local outside = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(outside)
  vim.api.nvim_buf_set_name(outside, vim.fn.tempname() .. ".lua")
  vim.cmd("GHLines")
  failure("rev-parse")
end)

vim.notify, vim.g.clipboard = real_notify, real_clipboard
vim.fn.delete(dir, "rf")
print(("Passed %d GHLines tests"):format(passed))
vim.cmd("qa!")
