-- options.lua
--
-- 本模块用于设置 Neovim 的核心选项 (vim.o) 和全局变量 (vim.g)。

local utils = require "fengwk.utils"
local globals = require "fengwk.globals"

-- 历史命令记录条数
vim.g.history = 200

-- 自动加载变更的文件
vim.o.autoread = true

-- 悬浮窗口透明度
vim.o.winblend = globals.theme.winblend
-- 弹出窗口透明度
vim.o.pumblend = globals.theme.pumblend

-- 搜索配置
vim.o.hlsearch = true   -- 搜索高亮
vim.o.incsearch = true  -- 搜索时定位到目标位置
vim.o.ignorecase = true -- 忽略大小写敏感匹配
vim.o.smartcase = true  -- 如果同时输入大小写则进行大小写敏感匹配

-- 背景色：dark、light
vim.o.bg = require "fengwk.globals".theme.bg
-- 真彩色支持
vim.o.termguicolors = true
-- 行高亮
vim.o.cursorline = true

-- 允许鼠标控制光标，nv 代表 normal 和 visual
vim.o.mouse = "nv"
-- vim.o.mouse = ""

-- 行号与相对行号显示
vim.o.number = true
vim.o.relativenumber = true

-- 滚动时保持上下边距
vim.o.scrolloff = 5

-- 自动换行
vim.o.wrap = true

-- 制表符与缩进
vim.o.tabstop = 4        -- 指定vim中显示的制表符宽度
vim.o.softtabstop = 4    -- 指定tab键宽度
vim.o.shiftwidth = 4     -- 设置 >> << == 时的缩进宽度
vim.o.expandtab = true   -- 使用空格进行缩进
vim.o.autoindent = true  -- 在这种缩进形式中，新增加的行和前一行使用相同的缩进形式
vim.o.smartindent = true -- 在这种缩进模式中，每一行都和前一行有相同的缩进量，同时这种缩进模式能正确地识别出花括号，当前一行为开花括号“{”时，下一新行将自动增加缩进；当前一行为闭花括号“}”时，则下一新行将取消缩进

-- 使用treesitter进行折叠
-- zc 折叠当前代码闭合片段，再次zc折叠上一层级的代码闭合片段
-- zm 折叠与当前已折叠同层级的代码片段
-- zo zc的反向操作
-- zr zm的反向操作
-- zR 打开所有折叠
-- 使用[z和]z可以跳到折叠区间的前后
vim.o.foldmethod = "indent"
vim.o.foldlevel = 999

-- 设置特殊符号显示
-- :set list      显示非可见字符
-- :set nolist    隐藏非可见字符
-- :set listchars 设置非可见字符的显示模式
vim.o.list = true
-- tab      制表符
-- trail    行末空格
-- precedes 左则超出屏幕范围部分
-- extends  右侧超出屏幕范围部分
vim.o.listchars = "tab:>-,trail:·,precedes:«,extends:»,"

-- 使用系统剪切板作为无名寄存器
-- vim.o.clipboard = 'unnamed'
-- https://stackoverflow.com/questions/30691466/what-is-difference-between-vims-clipboard-unnamed-and-unnamedplus-settings
-- vim.cmd("set clipboard^=unnamed,unnamedplus")
vim.opt.clipboard:append("unnamedplus")
-- vim.o.clipboard = 'unnamedplus'
-- ssh环境支持osc52，使ssh连接也能共享剪切板
if os.getenv("SSH_TTY") ~= nil then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy '+',
      ['*'] = require('vim.ui.clipboard.osc52').copy '*',
    },
    -- osc52的黏贴会卡住
    -- https://zhuanlan.zhihu.com/p/712125953
    paste = {
      ["+"] = function(_)
        return vim.split(vim.fn.getreg '"', "\n")
      end,
      ["*"] = function(_)
        return vim.split(vim.fn.getreg '"', "\n")
      end,
    },
  }
end

-- 持久化undo日志，使得退出重进也能进行undo操作
vim.o.undofile = true

-- 本机拼写检查
-- vim.cmd [[
-- set spell
-- set spelllang=en_us
-- ]]

-- 编码格式
vim.o.encoding = "utf-8"     -- vim内部字符表示编码
vim.o.fileencoding = "utf-8" -- 文件编码

-- 窗口拆分
-- vim.o.splitright = true -- 拆分后定位到右边
-- vim.o.splitbelow = true -- 拆分后定位到下方

-- 将"-"作为word的一部分
-- vim.opt.iskeyword:append("-")

-- 更快的代码高亮
-- vim.o.updatetime = 1000

-- 非 TTY 环境下（例如在某些 GUI 客户端中），使用更丰富的诊断符号
if not utils.is_tty() then
  vim.diagnostic.config {
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN] = "",
        [vim.diagnostic.severity.INFO] = "",
        [vim.diagnostic.severity.HINT] = "",
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
      },
    },
  }
end
