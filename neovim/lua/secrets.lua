local M = {}

function M.pass_func(key_name)
  local handle = io.popen("pass show " .. key_name)
  local result = handle:read("*l")
  handle:close()
  return function() return result end
end

return M
