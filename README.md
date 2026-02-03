# Neovim 配置

一个现代化、高度定制化的 Neovim 配置，采用全 Lua 实现，专为专业开发者打造。使用 lazy.nvim 进行插件管理，提供完整的 LSP、DAP、AI 辅助等功能支持。

## 设计理念

- **模块化架构**: 配置清晰划分为 `core`（核心设置）、`plugins`（插件管理）、`lsp`（LSP配置）、`dap`（调试配置）和 `custom`（自定义功能）
- **Lua 优先**: 全部使用 Lua 进行配置，获得最佳性能和一致性
- **LSP 优先**: 完整的语言服务器协议支持，使用 mason.nvim 自动安装管理
- **性能优化**: lazy.nvim 懒加载 + blink.cmp 高性能补全引擎
- **统一美学**: Catppuccin 主题贯穿所有 UI 组件，圆角边框 + 半透明效果

## 主要特性

- **高性能补全**: 使用 `blink.cmp` 替代传统 nvim-cmp，Rust 核心带来极速响应
- **多语言 LSP**: Java/Go/Python/JS/TS/C++/Lua/Bash 全栈支持
- **调试支持**: 内置 DAP 支持，覆盖 C++/Go/Python/JS/Java
- **AI 集成**: OpenCode + Avante 双 AI 辅助编程
- **智能功能**: LSP 生命周期管理、输入法自动切换、工作区管理
- **现代 UI**: Catppuccin 主题 + Lualine 状态栏 + Telescope dropdown 布局

## 文件结构

```
~/.config/nvim/
├── init.lua                 # 全局入口文件
├── lazy-lock.json           # 插件版本锁定
├── lua/fengwk/
│   ├── init.lua             # 核心模块入口
│   ├── globals.lua          # 全局变量与主题定义
│   ├── utils.lua            # 工具函数
│   ├── plugins-setup.lua    # lazy.nvim 引导与初始化
│   ├── core/
│   │   ├── init.lua         # 加载所有核心模块
│   │   ├── options.lua      # Vim 选项和全局设置
│   │   └── keymaps.lua      # 全局键映射
│   ├── plugins/             # 插件配置 (lazy.nvim spec)
│   │   ├── lsp.lua          # LSP + Mason 配置
│   │   ├── treesitter.lua   # 语法高亮和解析
│   │   ├── telescope.lua    # 模糊查找
│   │   ├── colorscheme.lua  # Catppuccin 主题
│   │   ├── blink-cmp.lua    # 补全引擎
│   │   ├── nvim-tree.lua    # 文件树
│   │   ├── lualine.lua      # 状态栏
│   │   ├── git.lua          # Git 集成
│   │   ├── opencode.lua     # AI 辅助
│   │   ├── avante.lua       # AI 编程
│   │   └── ...              # 其他插件
│   ├── lsp/                 # LSP 服务器配置
│   │   └── jdtls/           # Java LSP 深度定制
│   ├── dap/                 # 调试适配器配置
│   │   ├── cppdbg.lua       # C/C++ 调试
│   │   ├── delve.lua        # Go 调试
│   │   ├── js.lua           # JavaScript 调试
│   │   └── python.lua       # Python 调试
│   └── custom/              # 自定义功能模块
│       ├── im-switch.lua    # 输入法自动切换
│       ├── workspaces.lua   # 工作区管理
│       ├── bookmarks.lua    # 书签系统
│       ├── format-json.lua  # JSON 格式化
│       ├── open-url.lua     # URL 跳转
│       └── ...              # 其他自定义功能
├── lib/                     # 外部依赖
│   ├── compress-json.py     # JSON 压缩脚本
│   ├── format-json.py       # JSON 格式化脚本
│   ├── eclipse-pde/         # jdtls PDE 支持
│   └── sqllite/             # SQLite 库
└── snippets/                # 代码片段 (JSON 格式)
```

## 插件生态

### 核心插件

| 分类 | 插件 | 说明 |
|------|------|------|
| **插件管理** | `lazy.nvim` | 现代化插件管理器，支持懒加载 |
| **补全引擎** | `blink.cmp` | 高性能补全，Rust 核心 |
| **LSP** | `mason.nvim` + `nvim-lspconfig` | LSP 服务器自动安装管理 |
| **LSP UI** | `lspsaga.nvim` | 增强型 LSP 界面 |
| **搜索** | `telescope.nvim` | 模糊搜索框架 |
| **文件树** | `nvim-tree.lua` | 文件浏览器 |
| **语法** | `nvim-treesitter` | 基于语法树的高亮/折叠 |
| **主题** | `catppuccin` | 主题配色 |
| **状态栏** | `lualine.nvim` | 底部状态栏 |

### Git 工具

| 插件 | 功能 |
|------|------|
| `gitsigns.nvim` | 侧边栏 Git 状态 + 行内 Blame |
| `diffview.nvim` | Git Diff 视图 |
| `blame.nvim` | 交互式 Git Blame |

### 调试工具

| 插件 | 功能 |
|------|------|
| `nvim-dap` | 调试适配器协议客户端 |
| `mason-nvim-dap.nvim` | DAP 自动安装 |
| `nvim-dap-virtual-text` | 调试变量虚拟文本 |

### AI 工具

| 插件 | 功能 |
|------|------|
| `opencode.nvim` | AI 代码辅助 |
| `avante.nvim` | 类 Cursor 的 AI 编程体验 |

### 编辑增强

| 插件 | 功能 |
|------|------|
| `nvim-surround` | 成对符号操作 |
| `Comment.nvim` | 快速注释 |
| `nvim-autopairs` | 自动补全括号 |
| `indent-blankline.nvim` | 缩进线 + 作用域高亮 |
| `vim-illuminate` | 高亮相同符号 |
| `nvim-bqf` | 增强 Quickfix 窗口 |
| `satellite.nvim` | 侧边滚动条 |

## LSP 支持

| 语言 | 服务器 | 备注 |
|------|--------|------|
| Bash | `bashls` | |
| C/C++ | `clangd` | ARM 架构自动禁用 |
| Go | `gopls` | 需系统安装 `go` |
| Java | `jdtls` | 深度定制，含 PDE 支持 |
| Lua | `lua_ls` | |
| Python | `pylsp` | |
| JavaScript/TypeScript | `ts_ls` | 需安装 `npm` |
| CSS/LESS/SCSS | `cssls` | 需安装 `npm` |
| ESLint | `eslint` | 需安装 `npm` |

## DAP 支持

| 语言 | 适配器 |
|------|--------|
| C/C++ | `cppdbg` |
| Go | `delve` |
| JavaScript | `js-debug` |
| Python | `debugpy` |
| Java | `javadbg`, `javatest` |

## 快捷键

Leader 键: `Space` (空格)

### 通用键绑定

| 快捷键 | 模式 | 描述 |
|--------|------|------|
| `<Esc>` | Normal | 清除搜索高亮 |
| `<C-s>` | Normal | 保存当前缓冲区 |
| `<C-q>` | Normal | 关闭当前窗口/缓冲区 |
| `<leader>y` | Normal | 复制整个缓冲区 |
| `jk` | Insert | 退出到 Normal 模式 |
| `<A-=>`/`<A-->` | Normal | 增加/减少窗口高度 |
| `<A-+>`/`<A-_>` | Normal | 增加/减少窗口宽度 |
| `[q`/`]q` | Normal | Quickfix 前一项/后一项 |

### 文件与搜索 (Telescope)

| 快捷键 | 描述 |
|--------|------|
| `<leader>ff` | 查找文件 |
| `<leader>fF` | 查找文件（包含隐藏和忽略文件） |
| `<leader>fg` | 全局搜索 (Live Grep) |
| `<leader>fb` | 查找缓冲区 |
| `<leader>fo` | 最近打开的文件 |
| `<leader>fs` | 工作空间 |
| `<leader>ma` | 书签 |
| `<leader>e` | 定位当前文件在文件树 |
| `<leader>E` | 切换文件树 |

### LSP 操作

| 快捷键 | 描述 |
|--------|------|
| `gd` | 跳转到定义 |
| `gr` | 查看引用 |
| `gt` | 跳转到类型定义 |
| `K` | 显示悬浮文档 |
| `gs` | 文档符号 |
| `<leader>rn` | 重命名 |
| `<leader>ca` | 代码操作 |
| `<leader>fm` | 格式化代码 |
| `<leader>fd` | 诊断信息 |
| `[d`/`]d` | 上一个/下一个诊断 |

### 智能补全 (blink.cmp)

| 快捷键 | 模式 | 描述 |
|--------|------|------|
| `<Tab>` | Insert | 下一个补全项 / Snippet 下一个跳转点 |
| `<S-Tab>` | Insert | 上一个补全项 / Snippet 上一个跳转点 |
| `<CR>` | Insert | 确认补全 (仅在手动选中项时生效) |
| `<C-j>` | Insert/Select | Snippet 下一个跳转点 |
| `<C-k>` | Insert/Select | Snippet 上一个跳转点 |
| `<C-n>` | Insert | 手动触发补全 |
| `<C-c>` | Insert | 关闭补全窗口 |
| `<C-u>` | Insert | 向上滚动文档 |
| `<C-d>` | Insert | 向下滚动文档 |

### 调试 (DAP)

| 快捷键 | 描述 |
|--------|------|
| `<leader>db` | 切换断点 |
| `<leader>dc` | 条件断点 |
| `<leader>dl` | 日志断点 |
| `<leader>dC` | 清除所有断点 |
| `<leader>dr` | 切换 REPL |
| `<F5>` | 步入 |
| `<F6>` | 步过 |
| `<F7>` | 步出 |
| `<F8>` | 继续/开始调试 |
| `<leader>dt` | 终止调试 |

### 终端与 AI

| 快捷键 | 描述 |
|--------|------|
| `<leader>tt` | 切换浮动终端 |
| `<C-a>` | AI 提问 (OpenCode) |
| `<C-.>` | 切换 AI 窗口 |

### Git 操作

| 快捷键 | 描述 |
|--------|------|
| `<leader>gb` | Git Blame |

## Treesitter 配置

- **安装策略**: 自动安装全部语言解析器 (`ensure_installed = "all"`)
- **语法高亮**: 启用，大文件自动禁用保护
- **代码折叠**: 基于语法树 (`vim.treesitter.foldexpr()`)
- **增量选择**: `<CR>` 扩大选区，`<BS>` 缩小选区
- **自动缩进**: 基于语法树的智能缩进

## UI 配置

- **主题**: Catppuccin，圆角边框，15% 透明度
- **状态栏**: Lualine 极简风格，集成 LSP 进度动画和符号路径
- **搜索器**: Telescope 全部使用 dropdown 布局
- **缩进线**: indent-blankline，支持作用域高亮
- **滚动条**: satellite.nvim，显示诊断/搜索/Git 信息
- **文件树**: nvim-tree，与工作目录同步

## 特色功能

### 智能功能
- **LSP 生命周期管理**: 无活动缓冲区时自动停止 LSP 客户端，节省资源
- **输入法自动切换**: 进入/退出插入模式自动切换输入法状态
- **工作区管理**: 自定义 Workspace 系统 (`:WorkspaceAdd` / `:WorkspaceRemove`)
- **书签系统**: 自定义 Bookmark 功能 (`:BookmarkAdd` / `:BookmarkDelete`)

### 编辑增强
- **空行智能追加**: 在空行上按 `A` 将根据上一行的缩进定位光标
- **可视范围宏执行**: 在可视模式下，按 `@` 后跟寄存器以在每行执行宏
- **SSH 剪贴板支持**: 在 SSH 会话中使用 OSC52 协议进行剪贴板共享
- **大文件处理**: 自动为大文件（>128KB 或 >10,000 行）禁用语法高亮

### 工具集成
- **JSON 处理**: 通过 Python 脚本实现格式化/压缩
- **URL 跳转**: 支持 HTTP 链接和 `jdt://` 协议跳转
- **ASCII 流程图**: venn.nvim 绘图模式 (`:VennToggle`)

## 自定义命令

| 命令 | 描述 |
|------|------|
| `:ShowName` | 显示当前缓冲区的完整路径 |
| `:DiffChange` | 对比当前文件与磁盘上的原始版本 |
| `:DiffWith [file]` | 对比当前文件与指定文件 |
| `:WorkspaceAdd` | 添加工作区 |
| `:WorkspaceRemove` | 移除工作区 |
| `:BookmarkAdd` | 添加书签 |
| `:BookmarkDelete` | 删除书签 |
| `:VennToggle` | 切换 ASCII 绘图模式 |

## 安装和运行

### 系统要求
- Neovim 0.9+ (需要 LuaJIT)
- Git (用于插件安装)
- ripgrep (用于 Telescope live grep)
- Nerd Font (用于图标显示)

### 可选依赖
- `npm` - JavaScript/TypeScript LSP
- `go` - Go LSP
- `python3` - Python LSP 和 JSON 处理脚本
- `gcc/clang` - C/C++ LSP

### 安装步骤
1. 将此仓库克隆到 Neovim 配置目录：
   ```bash
   git clone <repo-url> ~/.config/nvim
   ```
2. 首次启动时，lazy.nvim 将自动引导并安装所有插件
3. Mason 将根据需要自动安装 LSP 服务器

### 插件管理
| 命令 | 描述 |
|------|------|
| `:Lazy` | 打开插件管理器 |
| `:Lazy update` | 更新插件 |
| `:Lazy sync` | 同步插件 |

### LSP 管理
| 命令 | 描述 |
|------|------|
| `:Mason` | 打开 LSP/DAP 管理器 |
| `:LspInfo` | 查看当前 LSP 状态 |

## 开发工作流

### 添加新插件
1. 在 `lua/fengwk/plugins/` 中创建新的 Lua 文件
2. 遵循 lazy.nvim 插件规范格式
3. 插件将通过 `plugins-setup.lua` 自动加载

### 自定义 LSP 设置
1. 在 `lua/fengwk/lsp/<server_name>/conf.lua` 创建配置文件
2. 创建 `lua/fengwk/lsp/<server_name>/setup.lua` 用于自定义设置函数
3. LSP 服务器初始化时将自动应用配置

### 添加自定义键绑定
1. 全局键绑定添加到 `lua/fengwk/core/keymaps.lua`
2. 插件相关键绑定添加到对应插件配置文件

## 故障排除

### 插件问题
1. 运行 `:Lazy` 查看插件状态
2. 使用 `:Lazy sync` 强制同步
3. 检查 `:messages` 获取错误信息

### LSP 问题
1. 运行 `:Mason` 检查 LSP 服务器安装状态
2. 使用 `:LspInfo` 查看连接的 LSP 服务器
3. 运行 `:checkhealth` 检查 Neovim 状态

### 性能问题
- 大文件会自动禁用语法高亮
- 使用 `:Lazy profile` 分析插件加载时间
- LSP 客户端会在无活动缓冲区时自动关闭

## Tabular 插件使用

该插件用于文本对齐，命令格式：

```
:Tabularize/{delimiter}[/[l{number}|c{number}|r{number}]...]
```

- `delimiter`: 分隔符号
- `l{number}`: 左对齐，设置空格数
- `c{number}`: 居中对齐
- `r{number}`: 右对齐

### 示例

```
# 原文本
asds|asdasf |qweqweqwr|sdf
aasdasassds| sdasf|  qweqwr|sdf

# 执行 :'<,'>Tabularize/|/l0
asds       |asdasf|qweqweqwr|sdf
aasdasassds|sdasf |qweqwr   |sdf
```
