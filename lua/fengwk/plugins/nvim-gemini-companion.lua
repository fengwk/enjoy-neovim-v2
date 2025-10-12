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

    -- 自动加载变更文件
    -- vim.api.nvim_create_autocmd(
    --   { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" },
    --   {
    --     group = group,
    --     pattern = "*",
    --     callback = function()
    --       -- 如果当前文件可编辑、非特殊类型文件、且可读、且没有修改过，则执行检查是否要重新加载
    --       if vim.bo.modifiable
    --         and not globals.is_special_ft(0)
    --         and vim.fn.filereadable(vim.fn.expand("%")) == 1
    --         and not vim.bo.modified then
    --         vim.cmd("checktime")
    --       end
    --     end,
    --     desc = "Auto reload file"
    --   }
    -- )
    --vim.api.nvim_create_autocmd("BufWriteCmd", {
    --  group = group,
    --  pattern = "*", -- 监听所有文件
    --  callback = function(args)
    --    print("aaaaaa: ", vim.inspect(vim.wo.diff))
    --    if not vim.wo.diff then
    --      -- 不是 diff 则不执行任何操作
    --      return
    --    end

    --    local file_path = vim.fn.expand(args.file .. ":p")
    --    print("xxxxxxxxxxxxxxxx: ", vim.inspect(file_path))
    --    vim.schedule(function()
    --      -- 遍历所有缓冲区，如果有打开一样路径的文件使用 checktime 刷新一次
    --      for _, buf_info in ipairs(vim.fn.getbufinfo({ buflisted = true })) do
    --        local buf_path = vim.fn.expand(buf_info.name .. ":p")
    --        if buf_path == file_path and buf_info.bufnr ~= args.buf then
    --          if #buf_info.windows > 0 then
    --            vim.cmd(buf_info.windows[1] .. "wincmd w | checktime")
    --          end
    --        end
    --      end
    --    end)
    --  end,
    --})
  end,
  keys = {
    { "<leader>aa", "<Cmd>GeminiToggle<CR>",             desc = "Toggle Gemini CLI" },
    { "<leader>aD", "<Cmd>GeminiSendFileDiagnostic<CR>", desc = "Send File Diagnostics" },
    { "<leader>ad", "<Cmd>GeminiSendLineDiagnostic<CR>", desc = "Send Line Diagnostics" },
    { "<leader>as", "<Esc><Cmd>GeminiSend<CR>",          mode = "v",                    desc = "Send Selected Text to AI Agent" },
  }
}
