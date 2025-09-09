# Neovim 配置

这是一个为现代开发工作流量身定制的、高度模块化的 Neovim 配置。它旨在提供一个快速、高效且易于扩展的编辑环境。

## 设计理念

- **模块化**: 配置被清晰地划分为 `core`（核心设置）和 `plugins`（插件管理），使得结构一目了然。
- **Lua 优先**: 尽可能使用 Lua 进行配置，以获得最佳性能和一致性。
- **清晰性**: 代码和注释都力求清晰，不仅解释“做什么”，更解释“为什么”。

## 文件结构

```
lua/fengwk/
├── core/
│   ├── init.lua      -- 加载所有核心模块
│   ├── options.lua   -- 核心 Vim 选项设置
│   ├── keymaps.lua   -- 全局和模式特定的快捷键
│   └── custom.lua    -- 自定义命令、自动命令和相关逻辑
├── plugins/
│   └── ...           -- 插件配置文件
├── globals.lua       -- 全局变量、枚举和特殊文件类型处理
├── utils.lua         -- 通用辅助函数
└── init.lua          -- 主入口文件，加载 core 和 plugins
```

## Leader 键

- `Space` (空格键) 被设置为 Leader 键和 Local Leader 键。

## 通用快捷键

| 快捷键      | 描述                               |
| ----------- | ---------------------------------- |
| `<Esc>`     | 清理搜索高亮                       |
| `<C-s>`     | 保存当前缓冲区                     |
| `<C-q>`     | 关闭当前缓冲区                     |
| `<C-z>`     | 禁用，防止误触退出 Neovim          |
| `<A-=>`     | 增加窗口高度                       |
| `<A-->`     | 减少窗口高度                       |
| `<A-+>`     | 增加窗口宽度                       |
| `<A-_>`     | 减少窗口宽度                       |
| `[q`        | Quickfix 列表上一项                |
| `]q`        | Quickfix 列表下一项                |
| `[Q`        | Quickfix 列表更旧的项              |
| `]Q`        | Quickfix 列表更新的项              |
| `<leader>y` | 复制整个缓冲区内容                 |
| `<C-c>`     | 复制到系统剪贴板 (在可视模式下)    |

## 插入模式快捷键

| 快捷键      | 描述                               |
| ----------- | ---------------------------------- |
| `jk`        | 从插入模式返回普通模式             |
| `JK`        | 从插入模式返回普通模式 (适配 Shift 延迟) |
| `Jk`        | 从插入模式返回普通模式 (适配 Shift 延迟) |
| `<C-j><C-k>`| 从可视、命令行、终端模式返回普通模式 |

## 自定义函数和命令

- **`@` (在可视模式下)**: 在选中的每行执行宏。
- **`A` (在普通模式下)**: 如果当前行为空，使用 'A' 时将遵循上一行的缩进。
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
