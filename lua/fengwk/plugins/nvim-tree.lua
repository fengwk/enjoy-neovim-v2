-- https://github.com/nvim-tree/nvim-tree.lua
-- nvim-tree 不进行懒加载 utils cd 依赖该模块
return {
  "nvim-tree/nvim-tree.lua",
  config = function()
    -- 禁用 nvim 内置的文件浏览使用 nvim-tree 替代, 非禁用情况下 edit 文件夹使用默认的文件浏览
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require "nvim-tree".setup {
      sync_root_with_cwd = true,
    }

    local keymap = vim.keymap.set
    keymap("n", "<leader>e", "<cmd>NvimTreeFindFile<cr>", { silent = true })
    keymap("n", "<leader>E", "<cmd>NvimTreeFindFileToggle<cr>", { silent = true })
  end,
  dependencies = {
    "nvim-tree/nvim-web-devicons"
  },
}
