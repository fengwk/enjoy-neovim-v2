require "fengwk"
function _G.get_visible_filetypes()
  local visible_fts = {}
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    -- 过滤有效窗口（排除悬浮窗、命令行窗口等）
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    local ft = vim.api.nvim_buf_get_option(buf_id, 'filetype')
    table.insert(visible_fts, ft)
  end
  -- 打印结果（或返回供其他逻辑使用）
  vim.notify("可见窗口文件类型: " .. table.concat(visible_fts, ", "))
  return visible_fts
end
