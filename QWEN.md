# Neovim Configuration for Qwen Code

## Project Overview

This is a highly modular and modern Neovim configuration designed for efficient development workflows. The configuration is written primarily in Lua and uses the lazy.nvim plugin manager. It features a comprehensive set of plugins for language server protocol (LSP) support, debugging, fuzzy finding, syntax highlighting, and more.

### Key Features
- **Modular Architecture**: Configuration is organized into clear modules under `lua/fengwk/`
- **Lua-First**: Configuration is written in Lua for optimal performance and consistency
- **LSP-First**: Full language server protocol support with mason.nvim for easy installation
- **Debugging Support**: Built-in DAP (Debug Adapter Protocol) support for multiple languages
- **Modern UI**: Catppuccin theme with rounded borders and transparency options
- **Smart Keybindings**: Thoughtfully designed keymaps with Space as the leader key

### Architecture
```
lua/fengwk/
├── core/
│   ├── init.lua      -- Loads all core modules
│   ├── options.lua   -- Core Vim options and global variables
│   └── keymaps.lua   -- Global and mode-specific keymaps
├── plugins/
│   └── ...           -- Plugin configurations
├── lsp/              -- LSP server configurations
├── dap/              -- DAP configurations
├── custom/           -- Custom configurations
├── globals.lua       -- Global variables and enums
├── utils.lua         -- Utility functions
└── init.lua          -- Main entry point
```

## Building and Running

### Installation
1. This configuration works with Neovim 0.9+ (requires LuaJIT)
2. Simply clone this repository to your Neovim config directory (`~/.config/nvim/` on Linux)
3. On first launch, lazy.nvim will automatically bootstrap itself and install all plugins
4. Mason will automatically install LSP servers as needed

### Launching Neovim
```bash
nvim [filename]
```

### Plugin Management
- **Install plugins**: `:Lazy`
- **Update plugins**: `:Lazy update`
- **Check for updates**: `:Lazy check`
- **Sync plugins**: `:Lazy sync`

### LSP Management
- **Install LSP servers**: `:Mason`
- **Check LSP status**: `:MasonLspconfig`
- **LSP info for current file**: `:LspInfo`

## Development Conventions

### Keybindings
The configuration uses Space (`<Space>`) as the leader key and Local Leader key.

#### General Keybindings
| Keybinding | Mode | Description |
|------------|------|-------------|
| `<Space>` | Normal | Leader key |
| `<Space>` | Local | Local leader key |
| `<Esc>` | Normal | Clear search highlights |
| `<C-s>` | Normal | Save current buffer |
| `<C-q>` | Normal | Close current buffer |
| `<C-z>` | Normal | Disabled (prevents suspending Neovim) |
| `<A-=>` | Normal | Increase window height |
| `<A-->` | Normal | Decrease window height |
| `<A-+>` | Normal | Increase window width |
| `<A-_>` | Normal | Decrease window width |
| `[q` | Normal | Quickfix previous item |
| `]q` | Normal | Quickfix next item |
| `[Q` | Normal | Quickfix older list |
| `]Q` | Normal | Quickfix newer list |
| `<leader>y` | Normal | Yank entire buffer |
| `<C-c>` | Visual | Yank to system clipboard |

#### Insert Mode Keybindings
| Keybinding | Mode | Description |
|------------|------|-------------|
| `jk` | Insert | Exit to normal mode |
| `JK` | Insert | Exit to normal mode (Shift delay) |
| `Jk` | Insert | Exit to normal mode (Shift delay) |
| `<C-j><C-k>` | Visual/Cmdline/Terminal | Exit to normal mode |

#### LSP Keybindings
| Keybinding | Mode | Description |
|------------|------|-------------|
| `K` | Normal | Show hover information |
| `<leader>rn` | Normal | Rename symbol |
| `<leader>ca` | Normal | Code action |
| `<leader>ca` | Visual | Range code action |
| `<leader>fm` | Normal | Format buffer |
| `<leader>fm` | Visual | Format selected range |
| `gs` | Normal | Document symbols |
| `gw` | Normal | Workspace symbols |
| `gr` | Normal | References |
| `g<leader>` | Normal | Implementation |
| `gd` | Normal | Definition |
| `gD` | Normal | Declaration |
| `gt` | Normal | Type definition |
| `[d` | Normal | Previous diagnostic |
| `]d` | Normal | Next diagnostic |
| `<leader>fd` | Normal | Telescope diagnostics |

#### DAP Keybindings
| Keybinding | Mode | Description |
|------------|------|-------------|
| `<leader>db` | Normal | Toggle breakpoint |
| `<leader>dc` | Normal | Conditional breakpoint |
| `<leader>dl` | Normal | Log point |
| `<leader>dC` | Normal | Clear all breakpoints |
| `<leader>dL` | Normal | Run last debug session |
| `<leader>dr` | Normal | Toggle REPL |
| `<F5>` | Normal | Step into |
| `<F6>` | Normal | Step over |
| `<F7>` | Normal | Step out |
| `<F8>` | Normal | Continue/Start debugging |
| `<leader>dt` | Normal | Terminate debugging |

#### Telescope Keybindings
| Keybinding | Mode | Description |
|------------|------|-------------|
| `<leader>fb` | Normal | Find buffers |
| `<leader>fB` | Normal | Find buffers (show all) |
| `<leader>ff` | Normal | Find files |
| `<leader>fF` | Normal | Find files (show all) |
| `<leader>fg` | Normal | Live grep |
| `<leader>fo` | Normal | Old files |
| `<leader>fh` | Normal | Help tags |
| `<leader>ft` | Normal | File types |
| `<leader>fs` | Normal | Workspaces |
| `<leader>ma` | Normal | Bookmarks |

### Configuration Structure

#### Core Modules
- `core/options.lua`: Vim options and global settings
- `core/keymaps.lua`: All keybindings
- `core/init.lua`: Loads all core modules

#### Plugin Modules
- `plugins/lsp.lua`: LSP and DAP configuration with automatic server installation
- `plugins/treesitter.lua`: Syntax highlighting and parsing
- `plugins/telescope.lua`: Fuzzy finder and search tools
- `plugins/colorscheme.lua`: Catppuccin theme configuration
- `plugins/nvim-cmp.lua`: Completion engine
- `plugins/nvim-tree.lua`: File tree explorer
- `plugins/lualine.lua`: Status line
- `plugins/git.lua`: Git integration (gitsigns)

#### Utility Modules
- `utils.lua`: General utility functions
- `globals.lua`: Global variables and helper functions

### Custom Features
- **Smart Append on Empty Line**: Pressing `A` on an empty line will position the cursor with proper indentation based on the previous line
- **Macro Execution on Visual Range**: In visual mode, press `@` followed by a register to execute a macro on each selected line
- **SSH Clipboard Support**: Uses OSC52 protocol for clipboard sharing when in SSH sessions
- **Automatic Workspace Detection**: Changes directory to project root when LSP initializes
- **Large File Handling**: Automatically disables syntax highlighting for large files (>128KB or >10,000 lines)

## Development Workflow

### Adding New Plugins
1. Create a new Lua file in `lua/fengwk/plugins/`
2. Follow the plugin specification format used in existing plugin files
3. The plugin will be automatically loaded via the `plugins-setup.lua` configuration

### Customizing LSP Settings
1. Create a new file in `lua/fengwk/lsp/[server_name]/conf.lua` for configuration
2. Create `lua/fengwk/lsp/[server_name]/setup.lua` for custom setup functions
3. The configuration will be automatically applied when the LSP server is initialized

### Adding Custom Keybindings
1. Add to `lua/fengwk/core/keymaps.lua` for global keybindings
2. Or add to specific plugin files for context-specific bindings

## Dependencies

This configuration requires:
- Neovim 0.9+
- Git (for plugin installation)
- ripgrep (for telescope live grep)
- Optional language-specific tools for LSP servers (gcc, npm, go, java, etc.)

## Troubleshooting

### Plugin Installation Issues
1. Run `:Lazy` to open the plugin manager
2. Check for errors in the lazy.nvim interface
3. Use `:Lazy sync` to force synchronization

### LSP Issues
1. Run `:Mason` to check LSP server installation
2. Use `:LspInfo` to see connected LSP servers
3. Check `:checkhealth` for general Neovim health

### Performance Issues
- Large files automatically have syntax highlighting disabled
- The configuration includes performance optimizations for large buffers
- Use `:Lazy` to manage plugin loading strategies

# Instructions

- 用户的目标语言是中文, 使用中文和用户沟通.
