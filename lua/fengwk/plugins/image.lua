return {
  {
    -- https://github.com/hakonharnes/img-clip.nvim
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        relative_to_current_file = true,
        show_dir_path_in_prompt = true,
        embed_image_as_base64 = false,
        drag_and_drop = {
          -- 关闭该功能，因为拖拽复制功能会包装 vim.paste 导致每次 URL paste 都需要下载内容，影响非图片 URL paste 性能
          enabled = false,
        },
        use_absolute_path = function()
          return false
        end
      },
    },
    keys = {
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
}
