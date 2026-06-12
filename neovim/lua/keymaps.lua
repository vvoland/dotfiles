local function selected_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]

  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  return start_line, start_col, end_line, end_col
end

local function copy_selection_with_location()
  local start_line, start_col, end_line, end_col = selected_range()
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if #lines == 0 then
    return
  end

  local visual_mode = vim.fn.visualmode()

  if visual_mode == "v" then
    if #lines == 1 then
      lines[1] = lines[1]:sub(start_col, end_col)
    else
      lines[1] = lines[1]:sub(start_col)
      lines[#lines] = lines[#lines]:sub(1, end_col)
    end
  elseif visual_mode == "\22" then
    for index, line in ipairs(lines) do
      lines[index] = line:sub(start_col, end_col)
    end
  end

  local filename = vim.fn.expand("%:.")
  if filename == "" then
    filename = "[No Name]"
  end

  local header
  if start_line == end_line then
    header = string.format("%s:%d", filename, start_line)
  else
    header = string.format("%s:%d-%d", filename, start_line, end_line)
  end

  local width = #tostring(end_line)
  local numbered_lines = {}
  for index, line in ipairs(lines) do
    local line_number = start_line + index - 1
    numbered_lines[index] = string.format("%" .. width .. "d: %s", line_number, line)
  end

  local text = header .. "\n" .. table.concat(numbered_lines, "\n")
  local ok = pcall(vim.fn.setreg, "+", text)

  if ok then
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
    print("Copied selection with filename and line numbers to clipboard")
  else
    vim.notify("Could not copy to clipboard register", vim.log.levels.ERROR)
  end
end

vim.keymap.set("v", "<leader>yc", copy_selection_with_location, {
  desc = "Copy selection with filename and line numbers",
})
