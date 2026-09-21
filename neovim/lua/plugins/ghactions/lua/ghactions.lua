local M = {}

local namespace = vim.api.nvim_create_namespace("GitHubActionsLinks")
local buffer_states = {}

-- Link destinations
--
-- Version-only comments select releases; otherwise keep the pinned source URL.

local function encode_url_component(value)
  return (value:gsub("[^%w%-%._~]", function(char)
    return ("%%%02X"):format(char:byte())
  end))
end

local function parse_action_link(line)
  local reference_start, reference, reference_end = line:match([[^%s*%-?%s*uses:%s*['"]?()([^%s'"#]+)()]])
  if not reference_start then
    return
  end

  local owner, repo, path, ref = reference:match("^([%w-]+)/([%w_.-]+)([^@]*)@(.+)$")
  if not owner or (path ~= "" and not path:match("^/[%w_./-]+$")) then
    return
  end

  local repository_url = "https://github.com/" .. owner .. "/" .. repo
  local version = line:sub(reference_end):match([[^['"]?%s+#%s*(v?%d[%w.+%-]*)%s*$]])
  local url
  if version then
    url = repository_url .. "/releases/tag/" .. encode_url_component(version)
  else
    url = repository_url .. "/tree/" .. encode_url_component(ref) .. path
  end

  -- Convert Lua string positions to Neovim's zero-based, end-exclusive columns.
  return url, reference_start - 1, reference_end - 1
end

-- Incremental hyperlinks
--
-- Buffer edits move existing extmarks; only the affected range needs rebuilding.

local function refresh_links(buf, start_row, end_row)
  vim.api.nvim_buf_clear_namespace(buf, namespace, start_row, end_row)

  for index, line in ipairs(vim.api.nvim_buf_get_lines(buf, start_row, end_row, false)) do
    local url, start_col, end_col = parse_action_link(line)
    if url then
      local row = start_row + index - 1
      vim.api.nvim_buf_set_extmark(buf, namespace, row, start_col, {
        end_row = row,
        end_col = end_col,
        url = url,
      })
    end
  end
end

local function queue_refresh(buf, start_row, old_end_row, new_end_row)
  local state = buffer_states[buf]
  local end_row = new_end_row

  -- -1 means the whole remaining buffer. Otherwise include the following
  -- line, where deleted extmarks can collapse.
  if end_row ~= -1 then
    end_row = end_row + 1
  end

  if state.start_row then
    state.start_row = math.min(state.start_row, start_row)

    if end_row == -1 or state.end_row == -1 then
      state.end_row = -1
    else
      local line_delta = new_end_row - old_end_row
      state.end_row = math.max(end_row, state.end_row + line_delta)
    end

    return
  end

  state.start_row, state.end_row = start_row, end_row

  -- Undo finishes moving extmarks after on_lines returns.
  vim.schedule(function()
    if buffer_states[buf] ~= state or not vim.api.nvim_buf_is_loaded(buf) then
      return
    end

    local pending_start, pending_end = state.start_row, state.end_row
    state.start_row, state.end_row = nil, nil

    refresh_links(buf, pending_start, pending_end)
  end)
end

-- Buffer lifecycle and navigation
--
-- Repeated filetype detection must not attach duplicate change listeners.

local function attach(buf)
  if buffer_states[buf] then
    return
  end
  buffer_states[buf] = {}
  refresh_links(buf, 0, -1)

  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, changed_buf, _, start_row, old_end_row, new_end_row)
      queue_refresh(changed_buf, start_row, old_end_row, new_end_row)
    end,

    on_reload = function(_, reloaded_buf)
      queue_refresh(reloaded_buf, 0, 0, -1)
    end,

    on_detach = function(_, detached_buf)
      buffer_states[detached_buf] = nil
    end,
  })

  vim.api.nvim_buf_call(buf, function()
    local fallback = "<Plug>(ghactions-gx-fallback)"
    -- Keep the original mapping's expression, remapping and callback semantics.
    -- Buffer-local mappings survive unloading, so do not capture our own gx again.
    if vim.fn.maparg(fallback, "n") == "" then
      local mapping = vim.fn.maparg("gx", "n", false, true)
      if next(mapping) then
        mapping.lhs = fallback
        mapping.lhsraw = vim.api.nvim_replace_termcodes(fallback, true, true, true)
        mapping.lhsrawalt = nil
        mapping.buffer = 1
        vim.fn.mapset("n", false, mapping)
      else
        vim.keymap.set("n", fallback, "<Nop>", { buffer = buf })
      end
    end

    vim.keymap.set("n", "gx", function()
      local url, start_col, end_col = parse_action_link(vim.api.nvim_get_current_line())
      local column = vim.api.nvim_win_get_cursor(0)[2]

      if not url or column < start_col or column >= end_col then
        return fallback
      end

      local _, err = vim.ui.open(url)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
      end
      return ""
    end, { buffer = buf, expr = true, desc = "Open GitHub Action or link under cursor" })
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("GitHubActionsLinks", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "yaml", "yaml.gha" },
    callback = function(args) attach(args.buf) end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local filetype = vim.bo[buf].filetype
    if vim.api.nvim_buf_is_loaded(buf) and (filetype == "yaml" or filetype == "yaml.gha") then
      attach(buf)
    end
  end
end

return M
