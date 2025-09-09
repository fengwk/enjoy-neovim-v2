return {
  {
    -- https://github.com/windwp/nvim-autopairs
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local nvim_autopairs = require "nvim-autopairs"
      nvim_autopairs.setup {
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
          java = false,
        },
        disable_filetype = { "TelescopePrompt", "spectre_panel", "dap-repl" },
        disable_in_macro = false,
        disable_in_visualblock = true,
        fast_wrap = {
          map = "<C-l>", -- ctrl+l，快速补充右侧符号
          chars = { "{", "[", "(", '"', "'", "`" },
          pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
          offset = 0, -- Offset from pattern match
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "PmenuSel",
          highlight_grey = "LineNr",
        },
      }

      -- 对于一些无法自动补充括号的LSP，下面的方法将增加这一功能
      local cmp = require "cmp"
      local cmp_autopairs = require "nvim-autopairs.completion.cmp"
      local handlers = require "nvim-autopairs.completion.handlers"
      cmp.event:on(
        "confirm_done",
        cmp_autopairs.on_confirm_done({
          filetypes = {
            -- "*" is a alias to all filetypes
            ["*"] = {
              ["("] = {
                kind = {
                  -- https://docs.rs/lsp/0.2.0/lsp/types/enum.CompletionItemKind.html
                  cmp.lsp.CompletionItemKind.Function,
                  cmp.lsp.CompletionItemKind.Method,
                  cmp.lsp.CompletionItemKind.Constructor,
                },
                handler = handlers["*"],
              },
            },
            -- 禁用指定类型的LSP
            tex = false,
            sh = false,
            bash = false,
          }
        })
      )
    end,
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  {
    -- https://github.com/windwp/nvim-ts-autotag
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {
      opts = {
        -- Defaults
        enable_close = true,          -- Auto close tags
        enable_rename = true,         -- Auto rename pairs of tags
        enable_close_on_slash = false -- Auto close on trailing </
      },
    },
  },
}
