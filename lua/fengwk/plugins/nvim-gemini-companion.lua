local globals = require "fengwk.globals"

return {
  -- "gutsavgupta/nvim-gemini-companion",
  "fengwk/nvim-gemini-companion",
  branch = "feat/autoreload",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
  config = function()
    require "gemini".setup {
      cmds = { "qwen" },
    }


    local group = vim.api.nvim_create_augroup("user_nvim_gemini_companion", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = { "terminalGemini" },
      callback = function()
        -- 快速关闭，使用命令 q 代替 toggle 避免最后一个缓冲区是 terminalGemini 是无法关闭
        vim.keymap.set({ "t", "n" }, "<C-q>", "<Cmd>q<CR>", { buffer = true, desc = "Quit Gemini CLI" })
        -- 避免与普通 terminal 冲突，这里需要使用 c-\\ c-n 来退出到 normal 模式
        vim.keymap.set({ "t" }, "<Esc>", "<Esc>", { noremap = true, buffer = true })
        -- 导航回代码
        vim.keymap.set({ "t", "n" }, "<C-e>", "<C-\\><C-n><C-w>h", { buffer = true })
      end,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      pattern = "*",
      callback = function()
        if vim.bo.filetype == "terminalGemini" then
          -- 先进入 normal 再进入 insert 确保任何情况下都能自动进入插入模式
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>i", true, true, true), "n", false)
        end
      end,
    })

    -- vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
    --   group = group,
    --   command = "if mode() != 'c' | checktime | endif",
    --   pattern = '*',
    -- })
  end,
  keys = {
    { "<leader>aa", "<Cmd>GeminiToggle<CR>",             desc = "Toggle Gemini CLI" },
    { "<leader>aD", "<Cmd>GeminiSendFileDiagnostic<CR>", desc = "Send File Diagnostics" },
    { "<leader>ad", "<Cmd>GeminiSendLineDiagnostic<CR>", desc = "Send Line Diagnostics" },
    { "<leader>as", "<Esc><Cmd>GeminiSend<CR>",          mode = "v",                    desc = "Send Selected Text to AI Agent" },
  }
}
