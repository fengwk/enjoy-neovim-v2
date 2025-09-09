-- git 相关配置
return {
  {
    -- https://github.com/lewis6991/gitsigns.nvim
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      -- Gitsigns toggle_current_line_blame
      current_line_blame = false, -- 默认情况下是否展示blame
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "right_align", -- "eol" | "overlay" | "right_align"
        delay = 0,
        ignore_whitespace = false,
      },
    },
  },
  {
    -- https://github.com/sindrets/diffview.nvim
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", opts = {} }
    },
  },
  {
    -- https://github.com/FabijanZulj/blame.nvim
    "https://github.com/FabijanZulj/blame.nvim",
    event = "VeryLazy",
    opts = {
      date_format = "%Y/%m/%d",
      mappings = {
        commit_info = "K",
        stack_push = "<TAB>",
        stack_pop = "<BS>",
        show_commit = "<CR>",
        close = { "<esc>", "q" },
      },
    },
    keys = {
      { "<leader>gb", "<cmd>BlameToggle<cr>", mode = "n" },
    },
  },
}
