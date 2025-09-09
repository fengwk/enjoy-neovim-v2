-- globals.lua
--
-- 本模块用于存放全局变量、枚举以及与特定缓冲区/文件类型相关的辅助函数。

local globals = {}

-- 特殊文件类型列表，这些通常是插件或功能性窗口，而非用户编辑的文件。
local special_fts = {
  "packer",           -- Packer 插件管理窗口
  "NvimTree",         -- NvimTree 文件浏览器
  "toggleterm",       -- ToggleTerm 终端
  "TelescopePrompt",  -- Telescope 搜索提示符
  "qf",               -- Quickfix 列表
  "aerial",           -- Aerial 代码大纲
  "dapui_scopes",     -- DAP UI: Scopes
  "dapui_stacks",     -- DAP UI: Stacks
  "dapui_breakpoints",-- DAP UI: Breakpoints
  "dapui_console",    -- DAP UI: Console
  "dap-repl",         -- DAP REPL
  "dapui_watches",    -- DAP UI: Watches
  "gitcommit",        -- Git 提交信息
  "gitrebase",        -- Git Rebase
  "diff",             -- Diff 模式
  "cmp_menu",         -- nvim-cmp 补全菜单
}

--- 检查给定的缓冲区是否属于特殊文件类型。
-- @param bufnr number 缓冲区编号。
-- @return boolean 如果是特殊文件类型，则返回 true，否则返回 false。
globals.is_special_ft = function(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return vim.tbl_contains(special_fts, ft)
end

globals.theme = {
  -- 为悬浮窗口提供透明度，[0..100]，0为不透明，在colorscheme中动态设置
  winblend = 15,
  -- 弹出窗口透明度, 如补全窗口
  pumblend = 15,
  -- "single", "double" or "rounded"
  border = "rounded",
}

return globals
