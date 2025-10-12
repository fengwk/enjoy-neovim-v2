# Neovim 配置

这是一个为现代开发工作流量身定制的、高度模块化的 Neovim 配置。它旨在提供一个快速、高效且易于扩展的编辑环境。配置主要使用 Lua 编写，并使用 lazy.nvim 插件管理器。它包含全面的插件集，支持语言服务器协议（LSP）、调试、模糊查找、语法高亮等功能。

## 设计理念

- **模块化**: 配置被清晰地划分为 `core`（核心设置）、`plugins`（插件管理）、`lsp`（LSP配置）和 `dap`（调试配置），使得结构一目了然。
- **Lua 优先**: 尽可能使用 Lua 进行配置，以获得最佳性能和一致性。
- **LSP 优先**: 完整的语言服务器协议支持，使用 mason.nvim 便于安装。
- **清晰性**: 代码和注释都力求清晰，不仅解释"做什么"，更解释"为什么"。

## 主要特性

- **模块化架构**: 配置组织在 `lua/fengwk/` 下的清晰模块中
- **Lua 优先**: 为最佳性能和一致性而编写的 Lua 配置
- **LSP 优先**: 使用 mason.nvim 的完整语言服务器协议支持
- **调试支持**: 对多种语言的内置 DAP（调试适配器协议）支持
- **现代 UI**: Catppuccin 主题，带圆角边框和透明度选项
- **智能键绑定**: 经过深思熟虑设计的键映射，空格键作为 leader 键

## 文件结构

```
lua/fengwk/
├── core/
│   ├── init.lua      -- 加载所有核心模块
│   ├── options.lua   -- 核心 Vim 选项和全局变量
│   └── keymaps.lua   -- 全局和模式特定的键映射
├── plugins/
│   └── ...           -- 插件配置文件
├── lsp/              -- LSP 服务器配置
├── dap/              -- DAP 配置
├── custom/           -- 自定义配置
├── globals.lua       -- 全局变量和枚举
├── utils.lua         -- 实用函数
└── init.lua          -- 主入口点
```

## 安装和运行

### 安装
1. 此配置适用于 Neovim 0.9+（需要 LuaJIT）
2. 将此仓库克隆到您的 Neovim 配置目录（Linux 上为 `~/.config/nvim/`）
3. 首次启动时，lazy.nvim 将自动引导自身并安装所有插件
4. Mason 将根据需要自动安装 LSP 服务器

### 启动 Neovim
```bash
nvim [filename]
```

### 插件管理
- **安装插件**: `:Lazy`
- **更新插件**: `:Lazy update`
- **检查更新**: `:Lazy check`
- **同步插件**: `:Lazy sync`

### LSP 管理
- **安装 LSP 服务器**: `:Mason`
- **检查 LSP 状态**: `:MasonLspconfig`
- **当前文件的 LSP 信息**: `:LspInfo`

## 开发约定

### 键绑定
配置使用空格键（`<Space>`）作为 leader 键和 Local Leader 键。

#### 通用键绑定
| 快捷键 | 模式 | 描述 |
|--------|------|------|
| `<Space>` | Normal | Leader 键 |
| `<Space>` | Normal | Local leader 键 |
| `<Esc>` | Normal | 清除搜索高亮 |
| `<C-s>` | Normal | 保存当前缓冲区 |
| `<C-q>` | Normal | 关闭当前缓冲区 |
| `<C-z>` | Normal | 禁用（防止暂停 Neovim） |
| `<A-=>` | Normal | 增加窗口高度 |
| `<A-->` | Normal | 减少窗口高度 |
| `<A-+>` | Normal | 增加窗口宽度 |
| `<A-_>` | Normal | 减少窗口宽度 |
| `[q` | Normal | Quickfix 前一项 |
| `]q` | Normal | Quickfix 后一项 |
| `[Q` | Normal | Quickfix 更旧列表 |
| `]Q` | Normal | Quickfix 更新列表 |
| `<leader>y` | Normal | 复制整个缓冲区 |
| `<C-c>` | Visual | 复制到系统剪贴板 |

#### Insert 模式键绑定
| 快捷键 | 模式 | 描述 |
|--------|------|------|
| `jk` | Insert | 退出到 Normal 模式 |
| `JK` | Insert | 退出到 Normal 模式（Shift 延迟） |
| `Jk` | Insert | 退出到 Normal 模式（Shift 延迟） |
| `<C-j><C-k>` | Visual/Cmdline/Terminal | 退出到 Normal 模式 |

#### LSP 键绑定
| 快捷键 | 模式 | 描述 |
|--------|------|------|
| `K` | Normal | 显示悬停信息 |
| `<leader>rn` | Normal | 重命名符号 |
| `<leader>ca` | Normal | 代码操作 |
| `<leader>ca` | Visual | 范围代码操作 |
| `<leader>fm` | Normal | 格式化缓冲区 |
| `<leader>fm` | Visual | 格式化选定范围 |
| `gs` | Normal | 文档符号 |
| `gw` | Normal | 工作区符号 |
| `gr` | Normal | 引用 |
| `g<leader>` | Normal | 实现 |
| `gd` | Normal | 定义 |
| `gD` | Normal | 声明 |
| `gt` | Normal | 类型定义 |
| `[d` | Normal | 上一个诊断 |
| `]d` | Normal | 下一个诊断 |
| `<leader>fd` | Normal | Telescope 诊断 |

#### DAP 键绑定
| 快捷键 | 模式 | 描述 |
|--------|------|------|
| `<leader>db` | Normal | 切换断点 |
| `<leader>dc` | Normal | 条件断点 |
| `<leader>dl` | Normal | 日志点 |
| `<leader>dC` | Normal | 清除所有断点 |
| `<leader>dL` | Normal | 运行最后的调试会话 |
| `<leader>dr` | Normal | 切换 REPL |
| `<F5>` | Normal | 步入 |
| `<F6>` | Normal | 步过 |
| `<F7>` | Normal | 步出 |
| `<F8>` | Normal | 继续/开始调试 |
| `<leader>dt` | Normal | 终止调试 |

#### Telescope 键绑定
| 快捷键 | 模式 | 描述 |
|--------|------|------|
| `<leader>fb` | Normal | 查找缓冲区 |
| `<leader>fB` | Normal | 查找缓冲区（显示全部） |
| `<leader>ff` | Normal | 查找文件 |
| `<leader>fF` | Normal | 查找文件（显示全部） |
| `<leader>fg` | Normal | 实时 grep |
| `<leader>fo` | Normal | 旧文件 |
| `<leader>fh` | Normal | 帮助标签 |
| `<leader>ft` | Normal | 文件类型 |
| `<leader>fs` | Normal | 工作区 |
| `<leader>ma` | Normal | 书签 |

### 配置结构

#### 核心模块
- `core/options.lua`: Vim 选项和全局设置
- `core/keymaps.lua`: 所有键绑定
- `core/init.lua`: 加载所有核心模块

#### 插件模块
- `plugins/lsp.lua`: LSP 和 DAP 配置，带自动服务器安装
- `plugins/treesitter.lua`: 语法高亮和解析
- `plugins/telescope.lua`: 模糊查找和搜索工具
- `plugins/colorscheme.lua`: Catppuccin 主题配置
- `plugins/nvim-cmp.lua`: 补全引擎
- `plugins/nvim-tree.lua`: 文件树浏览器
- `plugins/lualine.lua`: 状态栏
- `plugins/git.lua`: Git 集成（gitsigns）
- `plugins/editor-enhancer.lua`: 编辑器增强功能
- `plugins/autopairs.lua`: 自动配对括号
- `plugins/markdown.lua`: Markdown 支持
- `plugins/nvim-gemini-companion.lua`: Gemini 集成功能
- `plugins/avante.lua`: AI 驱动的代码编辑器
- `plugins/image.lua`: 图像支持
- `plugins/tmux.lua`: Tmux 集成

#### 实用模块
- `utils.lua`: 通用实用函数
- `globals.lua`: 全局变量和辅助函数

### 自定义功能
- **空行智能追加**: 在空行上按 `A` 将根据上一行的缩进定位光标
- **可视范围宏执行**: 在可视模式下，按 `@` 后跟寄存器以在每行执行宏
- **SSH 剪贴板支持**: 在 SSH 会话中使用 OSC52 协议进行剪贴板共享
- **自动工作区检测**: LSP 初始化时更改到项目根目录
- **大文件处理**: 自动为大文件（>128KB 或 >10,000 行）禁用语法高亮

## 开发工作流

### 添加新插件
1. 在 `lua/fengwk/plugins/` 中创建一个新的 Lua 文件
2. 遵循现有插件文件中使用的插件规范格式
3. 插件将通过 `plugins-setup.lua` 配置自动加载

### 自定义 LSP 设置
1. 在 `lua/fengwk/lsp/[server_name]/conf.lua` 中创建新文件进行配置
2. 创建 `lua/fengwk/lsp/[server_name]/setup.lua` 用于自定义设置函数
3. LSP 服务器初始化时将自动应用配置

### 添加自定义键绑定
1. 添加到 `lua/fengwk/core/keymaps.lua` 以获得全局键绑定
2. 或添加到特定插件文件以获得上下文特定的绑定

## 依赖

此配置需要：
- Neovim 0.9+
- Git（用于插件安装）
- ripgrep（用于 telescope 实时 grep）
- 可选的语言特定工具用于 LSP 服务器（gcc、npm、go、java 等）

## 故障排除

### 插件安装问题
1. 运行 `:Lazy` 以打开插件管理器
2. 检查 lazy.nvim 界面中的错误
3. 使用 `:Lazy sync` 强制同步

### LSP 问题
1. 运行 `:Mason` 以检查 LSP 服务器安装
2. 使用 `:LspInfo` 查看连接的 LSP 服务器
3. 检查 `:checkhealth` 以获得一般 Neovim 状态

### 性能问题
- 大文件会自动禁用语法高亮
- 配置包括针对大缓冲区的性能优化
- 使用 `:Lazy` 管理插件加载策略

## 自定义函数和命令

- **`@` (在可视模式下)**: 在选中的每行执行宏。
- **`A` (在 Normal 模式下)**: 如果当前行为空，使用 'A' 时将遵循上一行的缩进。
- **`:ShowName`**: 显示当前缓冲区的名称。
- **`:DiffChange`**: 对比当前文件与磁盘上的原始版本。
- **`:DiffWith [file]`**: 对比当前文件与指定文件（或一个空缓冲区）。

## tabular

该插件用于格式对齐，命令如下：

```
:Tabularize/{delimiter}[/[l{number}|c{number}|r{number}]...]
```
- delimiter：分隔的符号，每行都按这个符号分割成小段。
- l{number}：设置delimiter左右最近的字符有number个空格，且同一列的小段左对齐。
- c{number}：设置delimiter左右最近的字符有number个空格，且同一列的小段居中对齐。
- r{number}：设置delimiter左右最近的字符有number个空格，且同一列的小段右对齐。
- lcr可一起使用，甚至可以多组一起使用，此时按照lcr的排列顺序依次执行lcr的逻辑，这里有一点比较诡异，delimiter也会计算lcr的执行顺序，见示例二。

示例一：

```
asds|asdasf |qweqweqwr|sdf
aasdasassds| sdasf|  qweqwr|sdf

:'<,'>Tabularize/|/l0

asds       |asdasf|qweqweqwr|sdf
aasdasassds|sdasf |qweqwr   |sdf
```

示例二：

```
asds|asdasf asdasdas |sdsadasdqweqweqwr|sdfd
aasdasassds| sdasf|  qweqwr|sdf

:'<,'>Tabularize/|/l1c1r1

asds        | asdasf asdasdas | sdsadasdqweqweqwr | sdfd
aasdasassds |           sdasf |       qweqwr      | sdf
▲           ▲             ▲   ▲         ▲         ▲  ▲
l           c             r   l         c         r  l

如果想要达到左中右的目的，需要使用下面这个序列，其中l1用于占位
:'<,'>Tabularize/|/l1l1c1l1r1l1

asds        | asdasf asdasdas | sdsadasdqweqweqwr | sdfd
aasdasassds |      sdasf      |            qweqwr | sdf
```