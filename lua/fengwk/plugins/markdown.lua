local globals = require "fengwk.globals"

return {
  {
    -- 依赖 npm typescript
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_auto_close = 0
      -- vim.g.mkdp_open_to_the_world = 1 -- bind 0.0.0.0
      vim.g.mkdp_port = "" -- 自动端口防止多工程打开的时候端口冲突
      vim.g.mkdp_open_ip = "127.0.0.1" -- 公司的安全软件会禁用 localhost
      vim.g.mkdp_theme = globals.theme.bg
      vim.g.mkdp_filetypes = globals.markdown_filetypes

      vim.keymap.set("n", "<leader>mk", "<Cmd>MarkdownPreviewToggle<CR>", { silent = true, buffer = 0 })
    end,
    ft = globals.markdown_filetypes,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = globals.markdown_filetypes, -- 仅在 markdown 文件类型时加载
    opts = {
      file_types = globals.markdown_filetypes,
      -- https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/177
      render_modes = { "n", "v", "i", "c" },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons"
    },
  },
}
