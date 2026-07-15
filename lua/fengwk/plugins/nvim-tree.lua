-- https://github.com/nvim-tree/nvim-tree.lua
-- nvim-tree 不进行懒加载 utils cd 依赖该模块
return {
  "nvim-tree/nvim-tree.lua",
  tag = "v1.18.0",
  config = function()
    -- 禁用 nvim 内置的文件浏览使用 nvim-tree 替代, 非禁用情况下 edit 文件夹使用默认的文件浏览
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require "nvim-tree".setup {
      sync_root_with_cwd = true,
      -- 避免打开文件时按初始配置重新调整 tree 宽度
      actions = {
        open_file = {
          resize_window = false,
        },
      },
      renderer = {
        -- 将仅包含单层子目录的目录链合并为一个节点
        group_empty = true,
      },
    }

    local keymap = vim.keymap.set
    keymap("n", "<leader>e", "<cmd>NvimTreeFindFile<cr>", { silent = true })
    keymap("n", "<leader>E", "<cmd>NvimTreeFindFileToggle<cr>", { silent = true })

    -- 通过 `nvim 文件路径` 启动时, 自动以文件所在目录作为文件树根.
    local utils = require "fengwk.utils"
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("user_nvim_tree_root", { clear = true }),
      callback = function()
        local first = vim.fn.argv(0)
        if first == "" or vim.fn.filereadable(first) == 0 then
          return
        end
        utils.cd(vim.fs.dirname(vim.fn.fnamemodify(first, ":p")))
      end,
    })
  end,
  dependencies = {
    "nvim-tree/nvim-web-devicons"
  },
}
