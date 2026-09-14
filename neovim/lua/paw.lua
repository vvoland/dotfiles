-- One-way editor comments via Paw's CLI; routing and inbox ownership stay in Paw.
local M = {}

local max_payload_bytes = 1024 * 1024

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Paw" })
end

local function capture(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if vim.bo[bufnr].buftype ~= "" or name == "" or name:match("^%a[%w+.-]*:") then
    return nil, "Paw: no local file context for this buffer; sending comment only"
  end

  local file = vim.fn.fnamemodify(name, ":p")
  if file:sub(1, 1) ~= "/" then
    return nil, "Paw: cannot determine an absolute local path; sending comment only"
  end

  local start_line, end_line
  if opts.range > 0 then
    start_line, end_line = opts.line1, opts.line2
  else
    start_line = vim.api.nvim_win_get_cursor(0)[1]
    end_line = start_line
  end
  if start_line < 1 or end_line < start_line then
    error("Paw requires a positive, ordered line range")
  end

  return {
    file = file,
    filetype = vim.bo[bufnr].filetype,
    start_line = start_line,
    end_line = end_line,
    snapshot = table.concat(vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false), "\n"),
    modified = vim.bo[bufnr].modified,
  }
end

local function nonblank(value)
  return type(value) == "string" and value:find("%S") ~= nil
end

local function complete(result)
  -- vim.system reports its timeout as exit code 124 (not an IPC acknowledgement).
  if result.code == 124 then
    notify("Paw send timed out; delivery is uncertain and it may already be queued. "
      .. "Not retrying automatically; sending again could duplicate the comment.", vim.log.levels.WARN)
    return
  end
  if result.code ~= 0 or (result.signal or 0) ~= 0 then
    local detail = nonblank(result.stderr) and vim.trim(result.stderr)
      or ("process exited with code %s (signal %s)"):format(tostring(result.code), tostring(result.signal or 0))
    notify("Paw send failed: " .. detail .. "\nNot retried; if enqueue completed before the failure, "
      .. "sending again could duplicate the comment.", vim.log.levels.ERROR)
    return
  end

  local ok, response = pcall(vim.json.decode, result.stdout or "")
  if not ok or type(response) ~= "table" or response.status ~= "queued"
    or not nonblank(response.message_id) or not nonblank(response.instance_id) then
    -- Do not echo stdout: a broken command could have echoed the buffer snapshot.
    notify("Paw returned an invalid queue response; delivery is uncertain. "
      .. "Not retrying automatically; sending again could duplicate the comment.", vim.log.levels.ERROR)
    return
  end
  notify("Queued for Paw")
end

local function send(executable, text, context, context_notice)
  if not nonblank(text) then
    return
  end

  local ok, encoded = pcall(vim.json.encode, {
    version = 1,
    source = "neovim",
    text = text,
    context = context, -- nil omits the field, rather than encoding JSON null.
  })
  if not ok then
    notify("Paw: could not encode the comment and buffer context as JSON; nothing sent", vim.log.levels.ERROR)
    return
  end
  if #encoded > max_payload_bytes then
    notify("Paw: encoded payload exceeds 1 MiB; select fewer lines or shorten the comment. Nothing sent.",
      vim.log.levels.ERROR)
    return
  end
  if context_notice then
    notify(context_notice)
  end

  local spawned, err = pcall(vim.system, { executable, "send", "--json" }, {
    stdin = encoded,
    text = true,
    timeout = 5000,
  }, function(result)
    vim.schedule(function()
      complete(result)
    end)
  end)
  if not spawned then
    notify("Paw: could not start send; check that paw_executable is installed and executable. " .. tostring(err),
      vim.log.levels.ERROR)
  end
end

function M.setup(opts)
  opts = opts or {}
  local executable = opts.paw_executable or "paw"
  assert(nonblank(executable), "paw_executable must be a non-empty executable path or name")

  vim.api.nvim_create_user_command("Paw", function(command)
    -- Freeze the entire context before vim.ui.input can switch buffers/cursor/cwd.
    local ok, context, context_notice = pcall(capture, command)
    if not ok then
      notify("Paw: could not capture buffer context; nothing sent", vim.log.levels.ERROR)
      return
    end
    if command.args ~= "" then
      send(executable, command.args, context, context_notice)
      return
    end
    vim.ui.input({ prompt = "Comment for Paw: " }, function(text)
      send(executable, text, context, context_notice)
    end)
  end, {
    nargs = "*",
    range = true,
    desc = "Queue a comment and buffer lines for Paw in this Kitty pane",
  })
end

return M
