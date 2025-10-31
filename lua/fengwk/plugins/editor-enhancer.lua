local globals = require "fengwk.globals"
local utils = require "fengwk.utils"

-- 编辑器增强插件
return {
  {
    -- https://github.com/kylechui/nvim-surround
    -- ys[motion] 添加
    -- ds[motion] 删除
    -- cs[motion] 替换
    "kylechui/nvim-surround",
    version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    opts = {},
  },
  {
    -- https://github.com/gbprod/substitute.nvim
    -- rs[motion] 在 motion 范围黏贴
    "gbprod/substitute.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "rs",  function() require "substitute".operator() end, mode = "n" },
      { "rss", function() require "substitute".line() end,     mode = "n" },
      { "rS",  function() require "substitute".eol() end,      mode = "n" },
      { "rs",  function() require "substitute".visual() end,   mode = "x" },
    },
  },
  {
    -- https://github.com/numToStr/Comment.nvim
    -- Normal Mode
    -- gcc 注释行
    -- gc[motion] 注释motion范围内容
    -- Visual Mode
    -- gc 注释行
    'numToStr/Comment.nvim',
    event = "VeryLazy",
    opts = {},
  },
  {
    -- 保存文件时自动创建不存在的目录
    "jghauser/mkdir.nvim",
    event = "VeryLazy",
  },
  {
    -- https://github.com/lukas-reineke/indent-blankline.nvim
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    config = function()
      if utils.is_tty() then
        return
      end

      local ibl = require "ibl"
      -- local highlight = {
      --   "RainbowRed",
      --   "RainbowYellow",
      --   "RainbowBlue",
      --   "RainbowOrange",
      --   "RainbowGreen",
      --   "RainbowViolet",
      --   "RainbowCyan",
      -- }
      ibl.setup {
        -- 是否启用作用域高亮显示
        scope = { enabled = true },
        -- 多色缩进竖条
        -- indent = { highlight = highlight },
      }
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    -- https://github.com/kevinhwang91/nvim-bqf
    -- tab S-tab: qf 筛选
    -- zn: 使用筛选列表
    -- zf: 进入 fzf 模式, 同样可以使用 tab S-tab 筛选, 回车固定筛选列表 (单一选项会直接跳转)
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    opts = {
      preview = {
        winblend = globals.theme.winblend,
        show_scroll_bar = false,
        wrap = true,
      },
    },
    dependencies = {
      "junegunn/fzf",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      -- 仅在样式文件上支持名称颜色 etc red
      filetypes = {
        css = { names = true },
        less = { names = true },
        sass = { names = true },
        scss = { names = true },
        html = { names = true },
        "*", -- 必须放在最后
      },
      user_default_options = {
        names = false,
      },
    },
  },
  {
    "RRethy/vim-illuminate",
    event = "VeryLazy",
    config = function()
      local illuminate = require "illuminate"
      illuminate.configure({
        -- 指定提供符号引用的程序，可以指定的程序有：lsp、treesitter、regex
        -- 同时指定了多个时会按照排序的优先级获取
        providers = {
          'lsp',
          -- 'treesitter',
          -- 'regex',
        },
        -- 延迟的毫秒数
        delay = 100,
        -- 文件类型黑名单
        filetypes_denylist = { "packer", "NvimTree", "toggleterm", "TelescopePrompt", "qf", "aerial" },
        -- 允许的模式列表
        modes_allowlist = { 'n' },
        -- 当文件行数大于阈值时关闭该功能
        large_file_cutoff = 20000,
      })

      vim.keymap.set("n", "<C-j>", "<Cmd>lua require('illuminate').goto_next_reference()<CR>",
        { silent = true, desc = "Next Symbol" })
      vim.keymap.set("n", "<C-k>", "<Cmd>lua require('illuminate').goto_prev_reference()<CR>",
        { silent = true, desc = "Prev Symbol" })
    end,
  },
  {
    -- https://github.com/godlygeek/tabular
    "godlygeek/tabular",
    event = "VeryLazy",
  },
  {
    -- https://github.com/jbyuki/venn.nvim
    "jbyuki/venn.nvim",
    event = "VeryLazy",
    config = function()
      local function toggle_venn()
        if not vim.b.venn_enabled then
          -- 启用模式
          vim.b.venn_enabled = true
          vim.cmd [[setlocal ve=all]]

          -- 保存原始键映射
          vim.b.venn_original_mappings = {
            n = {
              J = vim.fn.maparg("J", "n"),
              K = vim.fn.maparg("K", "n"),
              L = vim.fn.maparg("L", "n"),
              H = vim.fn.maparg("H", "n"),
            },
            v = {
              b = vim.fn.maparg("b", "v"),
            }
          }

          -- 设置新键映射
          vim.keymap.set("n", "J", "<C-v>j:VBox<CR>", { buffer = true, noremap = true, silent = true })
          vim.keymap.set("n", "K", "<C-v>k:VBox<CR>", { buffer = true, noremap = true, silent = true })
          vim.keymap.set("n", "L", "<C-v>l:VBox<CR>", { buffer = true, noremap = true, silent = true })
          vim.keymap.set("n", "H", "<C-v>h:VBox<CR>", { buffer = true, noremap = true })
          vim.keymap.set("v", "b", ":VBox<CR>", { buffer = true, noremap = true, silent = true })

          vim.notify("Venn Enabled")
        else
          -- 禁用模式
          vim.cmd [[setlocal ve=]]

          -- 删除Venn设置的键映射
          vim.keymap.del("n", "J", { buffer = 0 })
          vim.keymap.del("n", "K", { buffer = 0 })
          vim.keymap.del("n", "L", { buffer = 0 })
          vim.keymap.del("n", "H", { buffer = 0 })
          vim.keymap.del("v", "b", { buffer = 0 })

          -- 恢复原始键映射
          local original = vim.b.venn_original_mappings
          for mode, maps in pairs(original) do
            for key, mapping in pairs(maps) do
              if mapping ~= "" then -- 只有原始映射存在时才恢复
                vim.keymap.set(mode, key, mapping, { buffer = true })
              end
            end
          end

          vim.b.venn_enabled = nil
          vim.b.venn_original_mappings = nil
          vim.notify("Venn Disabled")
        end
      end

      vim.api.nvim_create_user_command("VennToggle", toggle_venn, {})
    end
  },
  {
    -- https://github.com/lewis6991/satellite.nvim
    -- 滚动条+高亮(search diagnostic gitsigns marks quickfix)
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    config = function()
      require "satellite".setup {
        -- current_only = true,
      }
    end
  },
}
