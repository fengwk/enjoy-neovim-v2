-- https://lazy.folke.io/installation
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- 从 fengwk.plugins 模块导入配置
    { import = "fengwk.plugins" },
  },
  -- 这里设置的是 lazy 首次安装界面的主题
  install = { colorscheme = { "catppuccin" } },
  -- 自动检查插件更新
  checker = { enabled = false },
})
