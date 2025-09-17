-- 设置 Leader 键为空格
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 定义快捷键映射的辅助函数
local keymap = vim.keymap.set

-- ================
-- == 通用快捷键 ==
-- ================

-- 清理搜索高亮
keymap("n", "<Esc>", "<Cmd>noh<CR>", { silent = true, desc = "Clear Highlights" })

-- 退出 Terminal 模式
keymap("t", "<Esc>", "<C-\\><C-n>", { silent = true, desc = "Exit Terminal Mode" })

-- 保存当前缓冲区
keymap("n", "<C-s>", "<Cmd>w<CR>", { silent = true, desc = "Save Buffer" })

-- 关闭当前缓冲区
keymap("n", "<C-q>", "<Cmd>q<CR>", { silent = true, desc = "Close Buffer" })

-- 禁用 <C-z>，防止误触挂起 Neovim
keymap("n", "<C-z>", "<nop>", { desc = "Disable Ctrl-Z" })

-- 调整窗口大小
keymap("n", "<A-=>", "<Cmd>res +2<CR>", { silent = true, desc = "Increase Window Height" })
keymap("n", "<A-->", "<Cmd>res -2<CR>", { silent = true, desc = "Decrease Window Height" })
keymap("n", "<A-+>", "<Cmd>vertical res +2<CR>", { silent = true, desc = "Increase Window Width" })
keymap("n", "<A-_>", "<Cmd>vertical res -2<CR>", { silent = true, desc = "Decrease Window Width" })

-- Quickfix 列表导航
keymap("n", "[q", "<Cmd>cp<CR>", { silent = true, desc = "Quickfix Previous" })
keymap("n", "]q", "<Cmd>cn<CR>", { silent = true, desc = "Quickfix Next" })
keymap("n", "[Q", "<Cmd>colder<CR>", { silent = true, desc = "Quickfix Older" })
keymap("n", "]Q", "<Cmd>cnewer<CR>", { silent = true, desc = "Quickfix Newer" })

-- 复制整个缓冲区内容
keymap("n", "<leader>y", "mpggVGy`p", { noremap = true, desc = "Yank Entire Buffer" })

-- 兼容系统剪贴板的复制
keymap("x", "<C-c>", "y", { desc = "Yank to System Clipboard" })

-- ==============
-- == 插入模式 ==
-- ==============

-- 使用 "jk" 快速从插入模式返回普通模式
keymap({ "i" }, "jk", "<Esc>", { noremap = true, desc = "Insert Mode to Normal Mode" })
keymap({ "i" }, "JK", "<Esc>", { noremap = true, desc = "Insert Mode to Normal Mode (Shift Delay)" })
keymap({ "i" }, "Jk", "<Esc>", { noremap = true, desc = "Insert Mode to Normal Mode (Shift Delay)" })
keymap({ "i" }, "<C-j><C-k>", "<Esc>", { noremap = true, desc = "Insert Mode to Normal Mode" })

-- 在可视、命令行、终端模式下快速返回普通模式
keymap({ "v", "c", "t" }, "<C-j><C-k>", "<Esc>", { noremap = true, desc = "Exit Modes to Normal Mode" })

-- ========================
-- == 功能性快捷键与重写 ==
-- ========================

--- 在可视模式下，对选中的每一行执行宏
-- @usage 在可视模式下，按下 `@` 后再按下一个宏寄存器（如 `q`）
vim.cmd([[
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
echo "@".getcmdline()
execute ":'<,'>normal @".nr2char(getchar())
endfunction
]])

--- 如果当前行为非空，则 'A' 行为正常；如果为空，则自动缩进到上一行的位置
keymap("n", "A", function()
  local cur_line = vim.fn.line(".")
  local last_line = vim.fn.line("$")
  -- 检查当前行是否为空白行
  if cur_line > 1 and vim.fn.trim(vim.fn.getline(".")) == "" then
    vim.api.nvim_del_current_line()
    -- 如果删除的是最后一行，则在上一行之后新建一行 (o)
    -- 否则，在上一行之前新建一行 (O)，效果等同于在原位置新建
    if cur_line == last_line then
      vim.api.nvim_feedkeys("o", "n", true)
    else
      vim.api.nvim_feedkeys("O", "n", true)
    end
  else
    -- 正常执行 'A'
    vim.api.nvim_feedkeys("A", "n", true)
  end
end, { desc = "Smart Append on Empty Line" })
