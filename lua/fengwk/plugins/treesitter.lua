local utils = require "fengwk.utils"

-- 依赖 tar curl gcc gcc-c++
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local treesitter_config = require "nvim-treesitter.configs"
    treesitter_config.setup {
      ensure_installed = "all",    -- 自动安装清单，可以使用"all"安装所有解析器
      -- ipkg 目前有异常, https://github.com/nvim-treesitter/nvim-treesitter/issues/8029
      ignore_install = { "ipkg" }, -- 忽略安装的包
      sync_install = false,        -- 是否同步安装
      auto_install = true,         -- 进入缓冲区时自动安装

      highlight = {
        enable = true,
        -- 函数返回 true 将关闭高亮
        disable = function()
          return utils.is_large_buf()
        end,
        -- 禁用同时使用 Vim 传统的基于正则表达式的语法高亮和 Tree-sitter 的高亮
        additional_vim_regex_highlighting = false,
      },

      -- 增量选择语法树区间
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",
          node_incremental = "<CR>",
          scope_incremental = "<leader><CR>",
          node_decremental = "<BS>",
        },
      },

      -- Indentation based on treesitter for the = operator. NOTE: This is an experimental feature.
      indent = {
        enable = true
      },
    }

    -- Tree-sitter based folding
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end
}
