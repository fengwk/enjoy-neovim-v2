local utils = require "fengwk.utils"

-- 开启 Neovim 的标题设置功能
vim.o.title = true

-- 注册标题自动刷新
local group = vim.api.nvim_create_augroup("user_nvim_title_change", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged", "FocusGained" }, {
  group = group,
  callback = function()
    vim.schedule(utils.update_title)
  end,
})

-- 离开时恢复终端默认标题
local group2 = vim.api.nvim_create_augroup("user_nvim_leave", { clear = true })
vim.api.nvim_create_autocmd({ "VimLeave" }, {
  group = group2,
  callback = function()
    utils.reset_title()
  end,
})

-- 确保启动 Neovim 后标题能立即显示
utils.update_title()


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
