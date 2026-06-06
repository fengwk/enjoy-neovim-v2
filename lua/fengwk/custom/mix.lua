-- 进入后清理 jumplist, 避免意外的回跳
local clearjumps_group = vim.api.nvim_create_augroup("user_clearjumps", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = clearjumps_group,
  callback = function()
    vim.cmd("clearjumps")
  end
})

-- 展示当前缓冲区名称
vim.api.nvim_create_user_command("ShowName", function()
  print(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
end, { desc = "Show Current Buffer Name" })

-- 对比当前文件与磁盘上的原始文件的改变
vim.api.nvim_create_user_command("DiffChange", function()
  local filetype = vim.bo.filetype
  vim.cmd("diffthis")
  vim.cmd("vnew")
  vim.cmd("r #")
  vim.bo.filetype = filetype
  vim.cmd("diffthis")
  vim.cmd("normal! ggdd")
  vim.cmd("file [Original] " .. vim.fn.expand("#:t"))
  vim.cmd("setlocal bt=nofile bh=wipe nobl noswf nomodifiable")
  vim.wo.wrap = true
end, { desc = "Diff Current Buffer with Original" })

-- 对比当前文件与指定文件（或空缓冲区）的改变
vim.api.nvim_create_user_command("DiffWith", function(opts)
  local file = #opts.fargs > 0 and opts.fargs[1] or nil
  local filetype = vim.bo.filetype
  vim.cmd("diffthis")
  vim.cmd("vnew")
  if file and vim.fn.filereadable(file) == 1 then
    vim.cmd("edit " .. file)
    vim.cmd("file [Diff With] " .. vim.fn.fnamemodify(file, ":t"))
  else
    vim.cmd("file [Diff With]")
  end
  vim.bo.filetype = filetype
  vim.cmd("diffthis")
  vim.cmd("setlocal bt=nofile bh=wipe nobl noswf")
  vim.wo.wrap = true
end, { nargs = "?", complete = "file", desc = "Diff with a file or an empty buffer" })
