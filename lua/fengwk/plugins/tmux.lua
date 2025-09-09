-- TODO 待验证
--
local keymap = vim.keymap.set
-- 适配窗口交换
keymap("n", "<C-space>H", "<C-w>H")
keymap("n", "<C-space>J", "<C-w>J")
keymap("n", "<C-space>K", "<C-w>K")
keymap("n", "<C-space>L", "<C-w>L")

return {
  {
    -- https://github.com/aserowy/tmux.nvim
    "aserowy/tmux.nvim",
    opts = {
      copy_sync = {
        enable = false
      },
      navigation = {
        cycle_navigation = true,
        enable_default_keybindings = false,
        persist_zoom = false,
      },
      resize = {
        enable_default_keybindings = false,
        resize_step_x = 1,
        resize_step_y = 1,
      }
    },
    keys = {
      -- navigation
      { "<c-space>h", function() require "tmux".move_left() end,     mode = "n" },
      { "<c-space>j", function() require "tmux".move_bottom() end,   mode = "n" },
      { "<c-space>k", function() require "tmux".move_top() end,      mode = "n" },
      { "<c-space>l", function() require "tmux".move_right() end,    mode = "n" },
      -- resize
      { "<A-Left>",   function() require "tmux".resize_left() end,   mode = "n" },
      { "<A-Down>",   function() require "tmux".resize_bottom() end, mode = "n" },
      { "<A-Up>",     function() require "tmux".resize_top() end,    mode = "n" },
      { "<A-Right>",  function() require "tmux".resize_right() end,  mode = "n" },
    },
  },

}
