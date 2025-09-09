-- https://github.com/nvim-telescope/telescope.nvim
return {
  "nvim-telescope/telescope.nvim",
  -- tag = "0.1.8",
  branch = "0.1.x",
  event = "VeryLazy",
  config = function()
    local telescope = require "telescope"
    local actions = require "telescope.actions"
    local telescope_themes = require "telescope.themes"
    local telescope_builtin = require "telescope.builtin"

    telescope.setup {
      defaults = {
        -- 历史记录
        history = {
          path = vim.fs.joinpath(vim.fn.stdpath("data"), "telescope_history.sqlite3"),
          limit = 500,
        },
        winblend = require "fengwk.globals".theme.winblend,
        -- 路径展示
        path_display = {
          -- tail = true,
          truncate = 1, -- 从前边进行截断, 这通常符合预期, 因为需要看到文件名称, 1代表截断前的路径只展示一个字符
        },
        mappings = {
          i = {
            -- map actions.which_key to <C-h> (default: <C-/>)
            -- actions.which_key shows the mappings for your picker,
            -- e.g. git_{create, delete, ...}_branch for the git_branches picker
            -- ["<C-h>"] = "which_key"
            -- 回溯历史输入并进入了的内容
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            -- 上下移动
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            -- 转到搜索模式
            ["<C-f>"] = actions.to_fuzzy_refine,
            -- 上下移动preview
            -- <C-u>/<C-d>
            ["<C-c>"] = actions.close,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-Tab>"] = actions.toggle_all,
            ["<C-S-Q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
          n = {
            ["<C-c>"] = actions.close,
            ["q"] = actions.close,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-Tab>"] = actions.toggle_all,
            ["<C-S-Q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
      pickers = {
        find_files = {
          theme = "dropdown",
          -- previewer = false,
        },
        live_grep = {
          theme = "dropdown",
          -- previewer = false,
        },
        buffers = {
          theme = "dropdown",
          mappings = {
            n = {
              ["dd"] = "delete_buffer",
            }
          }
          -- previewer = false,
        },
        oldfiles = {
          theme = "dropdown",
          -- previewer = false,
        },
        filetypes = {
          theme = "dropdown",
        },
        colorscheme = {
          theme = "dropdown",
        },
        quickfixhistory = {
          theme = "dropdown",
        },
        help_tags = {
          theme = "dropdown",
        },
        git_commits = {
          theme = "dropdown",
        },
        git_branches = {
          theme = "dropdown",
        },
        lsp_references = {
          theme = "dropdown",
        },
        lsp_incoming_calls = {
          theme = "dropdown",
        },
        lsp_outgoing_calls = {
          theme = "dropdown",
        },
        lsp_document_symbols = {
          theme = "dropdown",
        },
        lsp_workspace_symbols = {
          theme = "dropdown",
        },
        lsp_dynamic_workspace_symbols = {
          theme = "dropdown",
        },
        diagnostics = {
          theme = "dropdown",
        },
        lsp_implementations = {
          theme = "dropdown",
        },
        lsp_definitions = {
          theme = "dropdown",
        },
        lsp_type_definitions = {
          theme = "dropdown",
        },
      },
      extensions = {
        ["ui-select"] = {
          telescope_themes.get_dropdown {},
        },

        ["workspaces"] = {
          telescope_themes.get_dropdown {},
        },

        -- ["jdtls"] = {
        --   telescope_themes.get_dropdown {},
        -- },

        ["bookmarks"] = {
          telescope_themes.get_dropdown {},
        },

        -- ["diff"] = {
        --   telescope_themes.get_dropdown {},
        -- },

        ["live_grep_args"] = {
          auto_quoting = true, -- enable/disable auto-quoting
          -- override default mappings
          -- default_mappings = {},
          mappings = { -- extend mappings
            i = {
              -- ["<C-k>"] = lga_actions.quote_prompt(),
              ["<C-k>"] = "move_selection_previous", -- 修改默认加引号行为
            }
          },
        },
      },
    }

    telescope.load_extension("ui-select")
    telescope.load_extension("workspaces")
    telescope.load_extension("live_grep_args")
    -- telescope.load_extension("jdtls")
    -- telescope.load_extension("diff")
    telescope.load_extension("bookmarks")
    telescope.load_extension("smart_history")

    local function telescope_builtin_buffers(show_all)
      telescope_builtin.buffers({
        ignore_current_buffer = not show_all,
        sort_mru = true,
      })
    end

    local function telescope_builtin_find_files(show_all)
      telescope_builtin.find_files({
        hidden = show_all,
        no_ignore = show_all,
        no_ignore_parent = show_all,
      })
    end

    local function telescope_builtin_live_grep_args()
      -- https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md
      -- -i ignore case
      -- -s 大小写敏感
      -- -w match word
      -- -e 正则表达式匹配
      -- -v 反转匹配
      -- -g 通配符文件或文件夹，可以用!来取反
      -- -F fixed-string 原意字符串，类似python的 r'xxx'
      -- 例如使用`-g **/lsp/* require`查找lsp目录下所有require字符
      -- telescope.extensions.live_grep_args.live_grep_args(telescope_themes.get_ivy())
      telescope.extensions.live_grep_args.live_grep_args(telescope_themes.get_dropdown())
    end

    local keymap = vim.keymap.set
    keymap("n", "<leader>fb", function() telescope_builtin_buffers(false) end, { desc = "Telescope Buffers" })
    keymap("n", "<leader>fB", function() telescope_builtin_buffers(true) end,
      { noremap = true, silent = true, desc = "Telescope Buffers (Show All)" })
    keymap("n", "<leader>ff", function() telescope_builtin_find_files(false) end, { desc = "Telescope Find Files" })
    keymap("n", "<leader>fF", function() telescope_builtin_find_files(true) end,
      { desc = "Telescope Find Files (Show All)" })
    keymap("n", "<leader>fg", telescope_builtin_live_grep_args, { desc = "Telescope Live Grep" })
    keymap("n", "<leader>fo", function() telescope_builtin.oldfiles() end, { desc = "Telescope Oldfiles" })
    keymap("n", "<leader>fh", function() telescope_builtin.help_tags() end, { desc = "Telescope Help Tags" })
    keymap("n", "<leader>ft", function() telescope_builtin.filetypes() end, { desc = "Telescope Filetypes" })
    keymap("n", "<leader>fs", "<Cmd>Telescope workspaces workspaces<CR>", { silent = true, desc = "Open Workspaces" })
    keymap("n", "<leader>ma", "<Cmd>Telescope bookmarks bookmarks<CR>", { silent = true, desc = "Open Bookmarks" })
    vim.api.nvim_create_user_command("DiffFile", function() telescope.extensions.diff.diff_file() end, {})
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",                         -- 必要依赖
    "nvim-telescope/telescope-live-grep-args.nvim",  -- live grep 增强, 依赖 ripgrep
    {
      "nvim-telescope/telescope-smart-history.nvim", -- 支持历史记录
      dependencies = {
        "kkharji/sqlite.lua"
      },
    },
    "nvim-telescope/telescope-ui-select.nvim", -- vim.ui.select 增强
  },
}
