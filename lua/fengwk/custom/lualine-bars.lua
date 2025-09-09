local bars = {}

bars.symbol_bar = function()
  local ok, wb = pcall(require, "lspsaga.symbol.winbar")
  if not ok then
    return ""
  end
  local bar = wb.get_bar()
  if not bar then
    return ""
  end
  -- 去除颜色高亮
  bar, _ = bar:gsub("%%**%%#[^#]+#", "")
  bar, _ = bar:gsub("%%#[^#]+#", "")
  return bar
end

-- 格式化信息样式
local function format_messages(messages)
  local result = {}
  local spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local ms = vim.loop.hrtime() / 1000000
  local frame = math.floor(ms / 120) % #spinners
  local i = 1
  for _, message in pairs(messages) do
    -- Only display at most 2 progress messages at a time to avoid clutter
    if i < 3 then
      table.insert(result, (message.percentage or 0) .. "%% " .. (message.title or ""))
      i = i + 1
    end
  end
  return table.concat(result, " ") .. " " .. spinners[frame + 1]
end

bars.lsp_progress = function()
  if vim.lsp.status then
    -- lsp信息 neovim 10+
    local lspStatus = vim.lsp.status()
    local pt = string.match(lspStatus, "%d+%%")
    if not pt then
      return ""
    end
    -- 需要对结果进行转义，否则lualine解析会报错
    pt = string.gsub(pt, "%%", "%%%%")
    return pt
  end
  -- vim.lsp.util.get_progress_messages在新版本中废弃
  local messages = vim.lsp.util.get_progress_messages()
  if #messages == 0 then
    return ""
  end
  return " " .. format_messages(messages)
end

return bars
