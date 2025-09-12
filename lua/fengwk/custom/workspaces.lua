local M = {}

local globals = require "fengwk.globals"
local utils = require "fengwk.utils"

local data_path = vim.fs.joinpath(vim.fn.stdpath("data"), "workspaces.json")

-- 内部状态
local data_cache = nil
local current_workspace = nil

local function write_data()
  if data_cache then
    utils.write_json(data_path, data_cache)
  end
end

--- 读取工作区数据
---@param force boolean|nil 如果为 true, 则强制从磁盘重新读取
function M.read_data(force)
  if data_cache == nil or force then
    data_cache = utils.read_json(data_path) or {}
  end
  return data_cache
end

--- 从给定路径向上查找匹配的工作区根目录
---@param path string 起始路径
---@return string|nil 找到的工作区根路径或 nil
local function find_workspace_root(path)
  if not path or path == "" then
    return nil
  end

  local data = M.read_data(true)
  if not next(data) then
    return nil
  end

  local current_path = utils.normalize_path(path)

  while current_path do
    -- 核心逻辑: 检查当前完整路径是否存在于工作区数据中
    if data[current_path] then
      return current_path
    end

    local parent_path = vim.fs.dirname(current_path)
    if parent_path == current_path then
      break
    end
    current_path = parent_path
  end

  return nil
end

--- 添加一个工作区
---@param ws_root string|nil 工作区路径, 默认为当前目录
function M.add(ws_root)
  ws_root = ws_root or vim.fn.getcwd()
  ws_root = utils.normalize_path(ws_root)

  if not utils.is_dir(ws_root) then
    vim.notify("Error: '" .. ws_root .. "' is not a directory.", vim.log.levels.ERROR)
    return
  end

  local data = M.read_data(true)
  if data[ws_root] then
    return
  end

  data[ws_root] = {}
  data_cache = data
  write_data()
  vim.notify("Workspace added: " .. ws_root)

  M.update_current_workspace()
  M.auto_record_workspace_buffer()
end

--- 移除一个工作区
---@param ws_root string 工作区根路径
function M.remove(ws_root)
  ws_root = utils.normalize_path(ws_root)

  local data = M.read_data(true)
  if not data[ws_root] then
    vim.notify("Workspace '" .. ws_root .. "' not found.", vim.log.levels.ERROR)
    return
  end

  data[ws_root] = nil
  data_cache = data
  write_data()
  vim.notify("Workspace removed: " .. ws_root)

  if ws_root == current_workspace then
    current_workspace = nil
  end
end

--- 列出所有工作区
---@return table 包含所有工作区路径的列表
function M.list()
  local data = M.read_data(true)
  local ws_list = {}
  for path, _ in pairs(data) do
    table.insert(ws_list, path)
  end
  table.sort(ws_list)
  return ws_list
end

--- 打开指定的工作区
---@param ws_root string 工作区根路径
function M.open(ws_root, force)
  if not ws_root or ws_root == "" then
    return
  end
  ws_root = utils.normalize_path(ws_root)

  if not force and ws_root == current_workspace then
    return
  end

  local data = M.read_data()
  if not data[ws_root] then
    vim.notify("Workspace '" .. ws_root .. "' not found.", vim.log.levels.ERROR)
    return
  end

  if not utils.cd(ws_root) then
    vim.notify("Workspace '" .. ws_root .. "' directory not accessible.", vim.log.levels.ERROR)
    return
  end

  local ws_name = vim.fn.fnamemodify(ws_root, ":t")
  local file_to_open = data[ws_root] and data[ws_root].last_file

  if not file_to_open or not utils.exists(file_to_open) then
    vim.notify("Workspace opened: " .. ws_name)
    return
  end

  vim.schedule(function()
    if globals.is_special_ft() then
      return
    end
    local ok, err = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(file_to_open))
    if ok then
      vim.notify("Workspace opened: " .. ws_name)
    else
      local clean_err = tostring(err):gsub("\n", " ")
      vim.notify("Failed to open last file: " .. clean_err, vim.log.levels.ERROR)
    end
  end)
end

function M.auto_record_workspace_buffer()
  if not current_workspace then
    return
  end

  if vim.bo.buftype ~= "" or vim.fn.bufname("%") == "" then
    return
  end

  if globals.is_special_ft() then
    return
  end

  local file_path = vim.fn.expand("%:p")
  if not file_path or file_path == "" then
    return
  end

  local data = M.read_data()
  if not data[current_workspace] then
    current_workspace = nil
    return
  end

  local last_file = utils.normalize_path(file_path)
  if vim.startswith(last_file, current_workspace) then
    vim.schedule(function()
      data[current_workspace] = {
        last_file = last_file,
      }
      data_cache = data
      write_data()
    end)
  end
end

function M.update_current_workspace()
  local ws_root = find_workspace_root(vim.fn.getcwd())
  if ws_root and ws_root ~= current_workspace then
    current_workspace = ws_root
    vim.notify("Entered workspace: " .. vim.fn.fnamemodify(ws_root, ":t"), vim.log.levels.INFO)
  elseif not ws_root and current_workspace then
    current_workspace = nil
  end
end

function M.get_current()
  return current_workspace
end

--- 设置插件
function M.setup()
  local group = vim.api.nvim_create_augroup("user_workspace", { clear = true })

  -- 恢复光标位置
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function()
      if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
        vim.cmd("normal! g'\"zz")
      end
    end,
  })

  -- 启动时自动打开工作区
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      M.update_current_workspace()
      if vim.fn.argc() == 0 then
        if current_workspace then
          M.open(current_workspace, true)
        end
      else
        M.auto_record_workspace_buffer()
      end
    end,
  })

  -- 切换目录时更新当前工作区状态
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = M.update_current_workspace,
  })

  -- 进入缓冲区后自动记录
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = group,
    callback = M.auto_record_workspace_buffer,
  })

  vim.api.nvim_create_user_command("WorkspaceAdd", function(args)
    M.add(args.fargs[1])
  end, { nargs = "?", complete = "dir" })

  vim.api.nvim_create_user_command("WorkspaceRemove", function(args)
    local target_path = args.fargs[1] or vim.fn.getcwd()
    local ws_root = find_workspace_root(target_path)
    if ws_root then
      vim.ui.input({ prompt = "Remove workspace '" .. ws_root .. "'? [y/N]: " }, function(input)
        if input and input:lower() == 'y' then
          print("\n") -- 清理输出内容
          M.remove(ws_root)
        end
      end)
    else
      vim.notify("Workspace not found at '" .. target_path .. "'.", vim.log.levels.WARN)
    end
  end, { nargs = "?", complete = "dir" })
end

return M
