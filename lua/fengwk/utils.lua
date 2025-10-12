-- utils.lua
--
-- 本模块提供了一系列通用的辅助函数

local globals = require "fengwk.globals"

local utils = {}

local sysname = string.lower(vim.loop.os_uname().sysname)
if string.find(sysname, "windows") ~= nil then
  utils.os = "win"
elseif string.find(sysname, "linux") ~= nil then
  utils.os = "linux"
elseif string.find(sysname, "darwin") ~= nil then
  utils.os = "macos"
else
  utils.os = "wsl"
end

if string.find(sysname, "windows") ~= nil then
  utils.sp = "\\"
else
  utils.sp = "/"
end

function utils.open(uri)
  if utils.os == "macos" then
    utils.system("open '" .. uri .. "'", true)
  elseif utils.os == "win" then
    utils.system("start " .. uri, false)
  else
    utils.system("xdg-open '" .. uri .. "'", true)
  end
end

--- 执行一个系统命令并返回其输出。
-- 这个函数使用 `io.popen` 而不是 `vim.fn.system`，因为它能更好地
-- 继承当前的 shell 环境，尤其是在处理路径和环境变量时。
-- @param cmd string|table 要执行的命令。
-- @param background boolean 如果为 true，则在后台执行命令。
-- @return string|nil 命令的输出，如果出错或在后台运行则返回 nil。
function utils.system(cmd, background)
  if type(cmd) == "table" then
    cmd = table.concat(cmd, " ")
  end
  -- 将标准错误重定向到标准输出，以便捕获所有输出
  cmd = cmd .. " 2>&1"
  if background then
    cmd = cmd .. " &"
  end

  local f = io.popen(cmd)
  if f == nil then
    return nil
  end

  if background then
    f:close()
    return nil
  else
    local res = f:read("*a")
    f:close()
    return res
  end
end

--- 检查当前 Neovim 实例是否在真实的 TTY 环境中运行。
-- 这对于判断是否应该启用某些仅在终端中有效的特性（如特定的 UI 符号）很有用。
-- 在 Mac 上，GUI 客户端的 `tty` 输出可能不标准，因此直接返回 false。
-- @return boolean 如果在 TTY 中，则返回 true。
function utils.is_tty()
  if vim.fn.has('mac') > 0 then
    return false
  end
  local tty = utils.system "tty"
  return tty and string.match(tty, "^/dev/tty") ~= nil
end

function utils.has_cmd(cmd)
  return vim.fn.executable(cmd) == 1
end

function utils.is_empty_str(str)
  return str == nil or str == ""
end

function utils.cd(cwd)
  if utils.is_empty_str(cwd) or not utils.is_dir(cwd) then
    return false
  end

  -- 将 vim 根路径定位到 cwd
  local cd_ok;
  if vim.fn.getcwd() == cwd then
    cd_ok = true;
  else
    cd_ok, _ = pcall(vim.cmd, "cd " .. cwd)
  end

  if cd_ok then
    -- 如果有 nvim-tree 将其根路径定位到 cwd
    -- 这可以确保即使 nvim-tree 已经被打开了依然能重新定位 cwd
    local tree_ok, nvim_tree_api = pcall(require, "nvim-tree.api")
    if tree_ok then
      nvim_tree_api.tree.change_root(cwd)
    end
  end

  return cd_ok
end

-- 创建一个节流函数，该函数在指定的 timeout 时间内最多执行一次 fn
-- @param fn {function} 要节流的函数
-- @param timeout {number} 节流的时间窗口，单位毫秒
-- @return {function} 返回一个新的、经过节流处理的函数
function utils.throttle(fn, timeout)
  local waiting = false
  return function(...)
    if not waiting then
      waiting = true
      fn(...)
      vim.defer_fn(function()
        waiting = false
      end, timeout)
    end
  end
end

-- 创建一个防抖函数，该函数在连续触发事件时，只在最后一次触发后的 timeout 时间后执行一次 fn
-- @param fn {function} 要防抖的函数
-- @param timeout {number} 防抖的延迟时间，单位是毫秒
-- @return {function} 返回一个新的、经过防抖处理的函数
function utils.debounce(fn, timeout)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
    end
    timer = vim.defer_fn(function()
      fn(unpack(args))
    end, timeout)
  end
end

-- 标记当前是否在 tmux 环境中
local is_in_tmux = os.getenv("TMUX") ~= nil
-- 开启 Neovim 的标题设置功能, 对非 tmux 环境生效
vim.o.title = true
--- 设置终端和 tmux 标题的统一函数
-- @param title string | nil 要设置的标题。如果为 nil 或空，则表示重置。
local function set_title(title)
  -- 对 title 进行基本的清洁，防止空值
  title = title or ""
  if is_in_tmux then
    -- 在 tmux 环境中，直接调用 tmux 命令
    -- 为了防止标题中的特殊字符（如 '）破坏命令，我们进行转义
    local escaped_title = vim.fn.escape(title, "'")
    vim.fn.system("tmux rename-window '" .. escaped_title .. "'")
  else
    -- 在非 tmux 环境中，使用 Neovim 的标准方式
    vim.o.titlestring = title
  end
end

--- 更新当前终端标题, 需开启 Neovim 的标题设置功能
--- vim.o.title = true
function utils.update_title()
  if globals.is_special_ft() then
    return
  end
  local filename = vim.fn.expand('%:t')
  if string.len(filename) > 0 then
    filename = " - " .. filename
  else
    filename = "" -- 如果没有文件名，则为空字符串
  end
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  -- 构建标题并直接赋值给 Neovim 的 titlestring 选项
  local title = "nvim ~ " .. cwd .. filename
  set_title(title)
end

function utils.reset_title()
  if is_in_tmux then
    -- 在 tmux 中，恢复为 shell 名称，这和您之前的逻辑类似
    local pwd = os.getenv('PWD') or ""
    local shell = os.getenv('SHELL') or "sh"
    shell = string.match(shell, "[^/]+$") or "shell"
    local dir = string.match(pwd, '.*/(.*)') or ""
    set_title(shell .. " ~ " .. dir)
  else
    -- 在普通终端中，清空 titlestring 即可让终端恢复默认标题
    set_title("")
  end
end

function utils.str_index(str, pattern)
  local i = 1
  local j = 1
  while i <= #str and j <= #pattern do
    if str:sub(i, i) == pattern:sub(j, j) then
      i = i + 1
      j = j + 1
    else
      i = i - j + 2
      j = 1
    end
  end
  return j == #pattern + 1 and i - #pattern or 0
end

function utils.write_file(filename, content)
  local file, _ = io.open(filename, "w")
  if file ~= nil then -- err == nil 说明文件存在
    file:write(content)
    file:close()
  end
end

function utils.read_file(filename)
  local file, _ = io.open(filename, "r")
  if file ~= nil then       -- err == nil 说明文件存在
    local res = file:read() -- 读取状态值
    file:close()
    return res
  end
  return nil
end

function utils.write_json(filename, obj)
  local json = vim.fn.json_encode(obj)
  utils.write_file(filename, json)
end

function utils.read_json(filename)
  local json = utils.read_file(filename)
  if not json then
    return nil
  end
  return vim.fn.json_decode(json)
end

function utils.is_uri(str)
  return string.match(str, "^[^:]+://") ~= nil
end

-- 检查文件是否存在
function utils.exists(filename)
  return filename and vim.loop.fs_stat(filename) ~= nil
end

function utils.is_dir(path)
  if not path then
    return false
  end
  local stat = vim.loop.fs_stat(path)
  if stat and stat.type == "directory" then
    return true
  end
  return false
end

-- 规范化路径
-- 1. 路径将被解析规范的
-- 2. 如果存在/a/路径将被解析为/a
function utils.normalize_path(path)
  if path then
    path = vim.fn.expand(path)
    if path and #path > 0 and path:sub(-1) == utils.sp then
      path = path:sub(1, -2)
    end
    -- windows不区分大小写处理时全部转为小写
    if utils.os == "win" then
      path = string.lower(path)
    end
  end
  return path
end

function utils.setup_lsp(server, conf, auto_enable)
  vim.lsp.config(server, conf)
  local lsp_conf = vim.lsp.config[server]
  if auto_enable and lsp_conf and lsp_conf.filetypes and #lsp_conf.filetypes > 0 then
    local first = true
    local function enable_lsp()
      if first then
        -- 必须通过 schedule 否则会出现 enable 未生效情况
        vim.schedule(function()
          vim.lsp.enable(server)
        end)
        first = false
      end
    end

    local group = vim.api.nvim_create_augroup("user_enable_lsp_" .. server, { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = lsp_conf.filetypes,
      group = group,
      callback = enable_lsp,
    })
  end
end

function utils.is_large_buf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  -- 检查文件大小是否超过阈值
  local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
  if ok and stats and stats.size > 1024 * 128 then
    return true
  end
  -- 检查文件行数是否超过阈值
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count and line_count > 10000 then
    return true
  end
  return false
end

return utils
