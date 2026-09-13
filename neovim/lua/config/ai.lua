-- Manually triggered inline (ghost text) completion from the OpenAI API.
-- <C-l> in insert mode requests a suggestion, then accepts it; :AI requests one
-- from anywhere. Moving, typing, or leaving insert throws it away.

local M = {}

local model = "gpt-5.6-sol"
local endpoint = "https://api.openai.com/v1/chat/completions"
local timeout = 20

-- Nothing streams here, so the request returns zero bytes until the model stops
-- reasoning, and a late suggestion is a useless one.
local reasoning_effort = "low"

-- ponytail: characters, not tokens. Count tokens if the bill ever shows up.
local prefix_chars, suffix_chars = 4000, 2000

local prompt = "You complete code at the cursor. The user sends the file with"
  .. " <CURSOR> marking the position. Reply with the raw text to insert there"
  .. " and nothing else: no explanation, no markdown fences, no repetition of"
  .. " the surrounding code."

local ns = vim.api.nvim_create_namespace("ai_ghost")

-- The one in-flight-or-showing suggestion. Its identity is the staleness check:
-- a request callback only touches the buffer while its own table is still here.
-- Fields: buf/row/col anchor (0-indexed), mark (extmark id, reused so the
-- pending marker becomes the suggestion in place), job, lines.
local active = nil

local key

local function api_key()
  key = key or os.getenv("OPENAI_API_KEY") or require("secrets").pass_func("OpenAI")()
  if not key then
    vim.notify("openai: no key in $OPENAI_API_KEY, the keychain, or pass", vim.log.levels.ERROR)
  end
  return key
end

-- The key must not go in argv: `ps` shows another process's command line.
local function auth_file(token)
  local path = vim.fn.tempname()
  local f = assert(io.open(path, "w"))
  vim.uv.fs_chmod(path, tonumber("600", 8))
  f:write(('header = "Authorization: Bearer %s"\n'):format((token:gsub('[\\"]', '\\%0'))))
  f:close()
  return path
end

local function clear()
  if not active then
    return
  end
  if active.job then
    active.job:kill("sigterm")
  end
  if vim.api.nvim_buf_is_valid(active.buf) then
    vim.api.nvim_buf_clear_namespace(active.buf, ns, 0, -1)
  end
  active = nil
end

local function render(state, lines)
  local below = {}
  for i = 2, #lines do
    below[i - 1] = { { lines[i], "Comment" } }
  end

  state.mark = vim.api.nvim_buf_set_extmark(state.buf, ns, state.row, state.col, {
    id = state.mark,
    virt_text = { { lines[1], "Comment" } },
    virt_text_pos = "inline",
    virt_lines = #below > 0 and below or nil,
  })
end

local function context(buf, row, col)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local cur = lines[row] or ""

  local head = table.concat(vim.list_slice(lines, 1, row - 1), "\n")
  local prefix = (row > 1 and head .. "\n" or "") .. cur:sub(1, col)

  local tail = vim.list_slice(lines, row + 1)
  local suffix = cur:sub(col + 1)
  if #tail > 0 then
    suffix = suffix .. "\n" .. table.concat(tail, "\n")
  end

  return prefix:sub(-prefix_chars), suffix:sub(1, suffix_chars)
end

-- Returns the text to insert, or nil plus a reason fit to show the user.
local function completion(out)
  if out.stdout == "" then
    return nil, "curl: " .. (out.stderr ~= "" and out.stderr or "exit " .. out.code)
  end

  local ok, res = pcall(vim.json.decode, out.stdout)
  if not ok then
    return nil, out.stdout
  end
  if res.error then
    return nil, res.error.message or out.stdout -- not every error shape has one
  end
  if not (res.choices and res.choices[1]) then
    return nil, out.stdout
  end

  -- The model is told not to fence its answer, but sometimes does anyway.
  local text = res.choices[1].message.content
  text = text:gsub("^```%w*\n", ""):gsub("\n?```%s*$", "")
  return text
end

function M.accept()
  if not (active and active.lines) then
    return
  end

  local s = active
  clear()
  vim.api.nvim_buf_set_text(s.buf, s.row, s.col, s.row, s.col, s.lines)

  -- Only the first inserted line is offset by the column it was spliced into.
  local last = s.lines[#s.lines]
  local col = #s.lines == 1 and s.col + #last or #last
  vim.api.nvim_win_set_cursor(0, { s.row + #s.lines, col })
end

function M.request()
  clear()
  local token = api_key()
  if not token then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local prefix, suffix = context(buf, row, col)

  local state = { buf = buf, row = row - 1, col = col }
  active = state
  render(state, { "…" })

  local body = vim.json.encode({
    model = model,
    reasoning_effort = reasoning_effort,
    messages = {
      { role = "system", content = prompt },
      {
        role = "user",
        content = "Filetype: " .. vim.bo[buf].filetype .. "\n\n" .. prefix .. "<CURSOR>" .. suffix,
      },
    },
  })

  local config = auth_file(token)
  local cmd = {
    "curl", "-sS",
    "--max-time", tostring(timeout),
    "--connect-timeout", "5",
    "-K", config,
    endpoint,
    "-H", "Content-Type: application/json",
    -- Bodies over 1KB otherwise wait for a 100-continue that buys us nothing.
    "-H", "Expect:",
    "-d", body,
  }

  state.job = vim.system(cmd, { text = true }, function(out)
    os.remove(config) -- before the staleness check: a killed job cleans up too
    vim.schedule(function()
      if active ~= state then
        return
      end
      state.job = nil

      local text, err = completion(out)
      if not text then
        clear()
        return vim.notify("openai: " .. (err or "no response"), vim.log.levels.ERROR)
      end
      if text == "" then
        clear()
        return vim.notify("openai: empty completion", vim.log.levels.WARN)
      end

      state.lines = vim.split(text, "\n")
      render(state, state.lines)
    end)
  end)
end

-- Pressing again while a request is in flight abandons it and retries.
function M.suggest()
  if active and active.lines then
    M.accept()
  else
    M.request()
  end
end

vim.api.nvim_create_user_command("AI", M.request, { desc = "AI: request inline suggestion" })
vim.keymap.set("i", "<C-l>", M.suggest, { desc = "AI: request, then accept, an inline suggestion" })

vim.api.nvim_create_autocmd({ "CursorMovedI", "TextChangedI", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("ai_ghost", { clear = true }),
  callback = clear,
})

return M
