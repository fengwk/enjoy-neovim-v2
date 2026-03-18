local M = {}

local function get_current_file_path()
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == "" then
    return nil
  end

  local cwd = vim.fn.getcwd()
  local relative_path = vim.fn.fnamemodify(file_path, ":.")
  if relative_path ~= file_path and not vim.startswith(relative_path, "../") then
    return vim.fs.joinpath(cwd, relative_path)
  end

  return vim.fn.fnamemodify(file_path, ":p")
end

local function copy_to_clipboard(text)
  vim.fn.setreg('"', text)
  vim.fn.setreg('+', text)
  vim.fn.setreg('*', text)
end

local function get_line_range_text(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  return table.concat(lines, "\n")
end

local function get_visual_selection_text()
  local visual_mode = vim.fn.visualmode()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]

  if start_row == 0 or end_row == 0 then
    return nil
  end

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  if vim.o.selection == "exclusive" and visual_mode ~= "V" then
    end_col = end_col - 1
  end

  if visual_mode == "V" then
    return get_line_range_text(start_row, end_row)
  end

  if visual_mode == "\022" then
    local block_start_col = math.min(start_col, end_col)
    local block_end_col = math.max(start_col, end_col)
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    for i, line in ipairs(lines) do
      if block_start_col > #line then
        lines[i] = ""
      else
        lines[i] = line:sub(block_start_col, math.min(block_end_col, #line))
      end
    end
    return table.concat(lines, "\n")
  end

  end_col = math.max(end_col, start_col)
  local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
  return table.concat(lines, "\n")
end

local function build_context_text(file_path, snippet)
  if not snippet or snippet == "" then
    return file_path
  end

  return string.format("%s\n\n```\n%s\n```", file_path, snippet)
end

local function copy_context(opts)
  local file_path = get_current_file_path()
  if not file_path then
    vim.notify("Current buffer has no file path.", vim.log.levels.WARN)
    return
  end

  local snippet = nil
  if opts.range > 0 then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    if start_pos[2] == opts.line1 and end_pos[2] == opts.line2 then
      snippet = get_visual_selection_text()
    else
      snippet = get_line_range_text(opts.line1, opts.line2)
    end
  end

  local content = build_context_text(file_path, snippet)
  copy_to_clipboard(content)

  if snippet and snippet ~= "" then
    vim.notify("Copied file path and selected snippet to clipboard.")
  else
    vim.notify("Copied file path to clipboard.")
  end
end

function M.setup()
  vim.api.nvim_create_user_command("CopyContext", copy_context, {
    range = true,
    desc = "Copy file path or selection as context",
  })
end

return M
