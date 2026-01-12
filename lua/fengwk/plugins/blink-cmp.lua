local globals = require "fengwk.globals"

return {
  "saghen/blink.cmp",
  dependencies = {
    "rafamadriz/friendly-snippets", -- 代码片段集合
    {
      "saghen/blink.compat",        -- nvim-cmp 兼容层
      version = "*",
      lazy = true,
      opts = {},
    },
    "rcarriga/cmp-dap", -- DAP 补全源
  },
  version = "1.*",      -- 使用发布版本

  -- https://cmp.saghen.dev/installation.html
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 快捷键映射
    -- 文档: https://cmp.saghen.dev/configuration/keymap.html
    keymap = {
      preset = "none", -- 禁用预设，使用自定义映射

      -- 文档滚动
      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },

      -- 智能跳转：优先处理补全，其次处理 snippet
      ["<C-j>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_next()
          elseif cmp.snippet_active() then
            return cmp.snippet_forward()
          end
        end,
        "fallback",
      },
      ["<C-k>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_prev()
          elseif cmp.snippet_active({ direction = -1 }) then
            return cmp.snippet_backward()
          end
        end,
        "fallback",
      },

      -- 确认补全
      ["<Tab>"] = { "select_and_accept", "fallback" },

      -- 手动触发或隐藏补全
      ["<C-n>"] = { "show", "fallback" },
      ["<C-c>"] = { "hide", "fallback" },
    },

    -- 外观配置
    appearance = {
      nerd_font_variant = "mono", -- 使用等宽 Nerd Font，确保图标对齐
    },

    -- 补全配置
    -- 文档: https://cmp.saghen.dev/configuration/completion.html
    completion = {
      -- 补全菜单
      menu = {
        border = globals.theme.border,
        winblend = globals.theme.winblend,
      },
      -- 文档窗口
      documentation = {
        auto_show = true, -- 自动显示文档
        window = {
          border = globals.theme.border,
          winblend = globals.theme.winblend,
        },
      },
    },

    -- 签名帮助
    -- 文档: https://cmp.saghen.dev/configuration/signature.html
    signature = {
      enabled = true,
      window = {
        show_documentation = false, -- 不在签名窗口中显示文档
        border = globals.theme.border,
        winblend = globals.theme.winblend,
      },
    },

    -- 补全源配置（默认启用的补全源，可通过 opts_extend 扩展）
    -- 文档: https://cmp.saghen.dev/configuration/sources.html
    sources = {
      default = {
        "lsp",      -- LSP 补全
        "path",     -- 路径补全
        "snippets", -- 代码片段
        "buffer",   -- 缓冲区补全
      },

      -- 特定文件类型的补全源
      per_filetype = {
        ["dap-repl"] = { "dap" },          -- DAP REPL
        ["dapui_watches"] = { "dap" },     -- DAP UI: Watches
        ["dapui_hover"] = { "dap" },       -- DAP UI: Hover
        ["dapui_scopes"] = { "dap" },      -- DAP UI: Scopes
        ["dapui_stacks"] = { "dap" },      -- DAP UI: Stacks
        ["dapui_breakpoints"] = { "dap" }, -- DAP UI: Breakpoints
        ["dapui_console"] = { "dap" },     -- DAP UI: Console
      },

      -- 补全源提供者配置
      providers = {
        -- DAP 补全源（通过 blink.compat 桥接 cmp-dap）
        dap = {
          name = "DAP",
          module = "blink.compat.source",
          opts = {
            -- 使用 cmp-dap 作为源
            source = "cmp_dap",
          },
        },
      },
    },

    -- 命令行模式补全
    -- 文档: https://cmp.saghen.dev/modes/cmdline
    cmdline = {
      keymap = {
        preset = "none",
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<Tab>"] = { "select_and_accept", "fallback" }, -- 使用 select_and_accept 避免插入模式错误
        ["<C-n>"] = { "show", "fallback" },
        ["<C-c>"] = { "hide", "fallback" },
      },
      completion = {
        menu = { auto_show = true }, -- 自动显示补全菜单
      },
    },

    -- 模糊匹配器（优先使用 Rust 实现以获得更好的性能和容错性）
    -- 文档: https://cmp.saghen.dev/configuration/fuzzy.html
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },

  -- 允许在其他地方扩展 sources.default
  opts_extend = { "sources.default" },
}
