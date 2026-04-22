local M = {}

-- 获取当前 buffer 的绝对文件路径；无文件 buffer 返回 nil。
local function get_current_file_path()
  local file_path = vim.api.nvim_buf_get_name(0)
  if file_path == "" then
    return nil
  end
  return vim.fn.fnamemodify(file_path, ":p")
end

-- 同时写入多个常见寄存器，方便终端与 GUI 场景直接粘贴。
local function copy_to_clipboard(text)
  vim.fn.setreg('"', text)
  vim.fn.setreg('+', text)
  vim.fn.setreg('*', text)
end

-- 格式化导出时使用的行号标签，统一使用 1-based 行号。
local function format_line_label(start_line, end_line)
  if start_line == end_line then
    return string.format("Line %d", start_line)
  end
  return string.format("Line %d-%d", start_line, end_line)
end

-- 读取连续行文本。
local function get_line_range_text(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  return table.concat(lines, "\n")
end

-- 将当前可视选区统一转换为“起止行 + 文本”。
-- 其中：
-- 1. v 模式保留字符级选区文本
-- 2. V 模式使用整行文本
-- 3. <C-v> 降级为多行整段文本，与 review comments 保持一致
local function get_visual_selection()
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

  if visual_mode == "V" or visual_mode == "\022" then
    return {
      start_line = start_row,
      end_line = end_row,
      text = get_line_range_text(start_row, end_row),
    }
  end

  if vim.o.selection == "exclusive" then
    end_col = math.max(end_col - 1, start_col)
  end

  local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
  return {
    start_line = start_row,
    end_line = end_row,
    text = table.concat(lines, "\n"),
  }
end

-- 将文件路径与可选代码片段组装为统一上下文格式。
local function build_context_text(file_path, selection)
  if not selection or not selection.text or selection.text == "" then
    return string.format("File: %s", file_path)
  end

  return table.concat({
    string.format("File: %s", file_path),
    "",
    format_line_label(selection.start_line, selection.end_line),
    "```",
    selection.text,
    "```",
  }, "\n")
end

-- ContextCopy 支持：
-- 1. 普通模式下仅复制文件路径
-- 2. v / V / <C-v> 下复制文件路径 + 选中文本 + 行号范围
local function context_copy(opts)
  local file_path = get_current_file_path()
  if not file_path then
    vim.notify("Current buffer has no file path.", vim.log.levels.WARN)
    return
  end

  local selection = nil
  if opts.range > 0 then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    if start_pos[2] == opts.line1 and end_pos[2] == opts.line2 then
      selection = get_visual_selection()
    else
      selection = {
        start_line = opts.line1,
        end_line = opts.line2,
        text = get_line_range_text(opts.line1, opts.line2),
      }
    end
  end

  local content = build_context_text(file_path, selection)
  copy_to_clipboard(content)
end

function M.setup()
  vim.api.nvim_create_user_command("ContextCopy", context_copy, {
    range = true,
    desc = "Copy file path or selection as context",
  })
end

return M
