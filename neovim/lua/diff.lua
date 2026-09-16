local M = {}

local function git(dir, args)
  local argv = { "git", "-C", dir }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { timeout = 10000 }):wait()
  if result.code ~= 0 then
    error(vim.trim(result.stderr or "") ~= "" and vim.trim(result.stderr)
      or ("Git command failed: " .. table.concat(args, " ")), 0)
  end
  return result.stdout or ""
end

local function open_diff(revision)
  local cwd = vim.fn.getcwd()
  local root = git(cwd, { "rev-parse", "--show-toplevel" }):gsub("\n$", "")
  local commit = git(root, { "rev-parse", "--verify", "--end-of-options", revision .. "^{commit}" }):gsub("\n$", "")
  -- Disable rename detection so every right pane has its own working-tree path.
  local entries = vim.split(git(root, {
    "diff", "--no-ext-diff", "--no-textconv", "--no-renames", "--name-status", "-z", commit, "--",
  }), "\0", { plain = true, trimempty = true })
  if #entries == 0 then
    vim.notify("Diff: No changes against " .. revision, vim.log.levels.INFO)
    return
  end

  -- Read all baselines before changing the layout, including validation of blob types.
  local files = {}
  for i = 1, #entries, 2 do
    local status, path = entries[i], entries[i + 1]
    local contents = status == "A" and "" or git(root, { "cat-file", "blob", commit .. ":" .. path })
    if vim.fn.isdirectory(root .. "/" .. path) == 1 then
      error("Cannot diff a directory or submodule: " .. path, 0)
    end
    local lines = vim.split(contents, "\n", { plain = true })
    if contents:sub(-1) == "\n" then table.remove(lines) end
    table.insert(files, { path = path, lines = lines })
  end

  local reuse = #vim.api.nvim_tabpage_list_wins(0) == 1
    and vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" and not vim.bo.modified
    and vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
  local first_tab, first_window
  for i, file in ipairs(files) do
    if i > 1 or not reuse then vim.cmd.tabnew() end
    vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. file.path))
    local right = vim.api.nvim_get_current_win()
    local filetype = vim.bo.filetype
    local left = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(left, "diff://" .. left .. "/" .. revision .. "/" .. file.path)
    vim.api.nvim_buf_set_lines(left, 0, -1, false, file.lines)
    vim.bo[left].filetype = filetype
    vim.bo[left].bufhidden = "wipe"
    vim.bo[left].swapfile = false
    vim.bo[left].modified = false
    vim.bo[left].modifiable = false
    vim.bo[left].readonly = true
    vim.cmd("leftabove vsplit")
    vim.api.nvim_win_set_buf(0, left)
    vim.cmd.diffthis()
    vim.api.nvim_set_current_win(right)
    vim.cmd.diffthis()
    if not first_tab then
      first_tab, first_window = vim.api.nvim_get_current_tabpage(), right
    end
  end
  vim.api.nvim_set_current_tabpage(first_tab)
  vim.api.nvim_set_current_win(first_window)
end

function M.setup()
  vim.api.nvim_create_user_command("Diff", function(command)
    local ok, err = pcall(open_diff, command.fargs[1] or "HEAD~1")
    if not ok then vim.notify("Diff: " .. tostring(err), vim.log.levels.ERROR) end
  end, {
    nargs = "?",
    desc = "Diff a revision (default HEAD~1) against editable working-tree files",
  })
end

return M
