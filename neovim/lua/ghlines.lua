local M = {}

local function git(dir, args)
  local argv = { "git", "-C", dir }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { text = true, timeout = 3000 }):wait()
  if result.code ~= 0 then
    error("Git command failed: " .. table.concat(args, " "), 0)
  end
  return (result.stdout or ""):gsub("\n$", "")
end

local function encode_path(path)
  return (path:gsub("[^%w%-%._~/]", function(char)
    return ("%%%02X"):format(char:byte())
  end))
end

local function repository_url(remote)
  local path = remote:match("^git@github%.com:(.+)$")
    or remote:match("^https?://github%.com/(.+)$")
    or remote:match("^ssh://git@github%.com/(.+)$")
    or remote:match("^ssh://git@github%.com:%d+/(.+)$")
  if not path then
    error("origin is not a supported GitHub remote (HTTPS or SSH)", 0)
  end
  path = path:gsub("/$", ""):gsub("%.git$", "")
  if not path:match("^[%w_.-]+/[%w_.-]+$") then
    error("origin does not identify a GitHub owner/repository", 0)
  end
  return "https://github.com/" .. path
end

local function permalink(command)
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" or vim.bo.buftype ~= "" or name:match("^%a[%w+.-]*:") then
    error("Open a local, committed file first", 0)
  end
  local dir = vim.fn.fnamemodify(name, ":h")
  -- Resolve relative to the buffer, not Neovim's working directory.
  local prefix = git(dir, { "rev-parse", "--show-prefix" })
  local path = prefix .. vim.fn.fnamemodify(name, ":t")
  local commit = git(dir, { "rev-parse", "--verify", "HEAD" })
  git(dir, { "cat-file", "-e", commit .. ":" .. path })
  local base = repository_url(git(dir, { "remote", "get-url", "origin" }))
  local first = command.range > 0 and command.line1 or vim.api.nvim_win_get_cursor(0)[1]
  local last = command.range > 0 and command.line2 or first
  local anchor = "#L" .. first .. (last ~= first and ("-L" .. last) or "")
  local changed = vim.bo.modified
    or git(dir, { "diff", "--no-ext-diff", "--no-textconv", "--name-only", "HEAD", "--",
      ":(top,literal)" .. path }) ~= ""
  return base .. "/blob/" .. commit .. "/" .. encode_path(path) .. anchor, changed
end

function M.setup()
  vim.api.nvim_create_user_command("GHLines", function(command)
    local ok, url, changed = pcall(permalink, command)
    if not ok then
      vim.notify("GHLines: " .. tostring(url), vim.log.levels.ERROR)
      return
    end
    -- Keep a usable copy even when no system clipboard provider is installed.
    vim.fn.setreg('"', url)
    local copied = false
    if vim.fn.has("clipboard") == 1 then
      copied = pcall(vim.fn.setreg, "+", url)
    end
    vim.notify(url .. "\nCopied to " .. (copied and "clipboard" or "unnamed register")
      .. (changed and "\nLocal edits exist; line numbers refer to HEAD, not your edits." or ""),
      changed and vim.log.levels.WARN or vim.log.levels.INFO, { title = "GHLines" })
  end, {
    range = true,
    desc = "Copy a GitHub permalink to the current line or selected range at HEAD",
  })
end

return M
