local M = {}

-- run returns the first line of cmd's stdout, or nil if it failed. stderr is
-- captured rather than left to scribble over the UI: a missing keychain entry
-- or a locked password store is an ordinary outcome here, not one worth
-- redrawing the screen for.
local function run(cmd)
  if vim.fn.executable(cmd[1]) ~= 1 then
    return nil
  end

  local out = vim.system(cmd, { text = true }):wait()
  if out.code ~= 0 then
    return nil
  end

  local line = vim.split(out.stdout, "\n")[1]
  return line ~= "" and line or nil
end

function M.pass_func(key_name)
  -- argv, not a shell string, so key_name never reaches a parser.
  local result = run({ "security", "find-generic-password", "-w", "-s", key_name })
    or run({ "pass", "show", key_name })

  return function() return result end
end

return M