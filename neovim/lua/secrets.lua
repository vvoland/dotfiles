local M = {}

function M.pass_func(key_name)
  if vim.fn.executable("security") then
    local handle = io.popen("security find-generic-password -w -s " .. key_name)
    local result = handle:read("*l")
    handle:close()
    if result then
      return function() return result end
    end
  end

  local handle = io.popen("pass show " .. key_name)
  local result = handle:read("*l")
  handle:close()
  return function() return result end
end

return M
