--[[
-- Neovim 输入法自动切换插件
--
-- 功能:
-- - 当离开插入模式进入普通模式时，自动切换到英文输入法。
-- - 当再次进入插入模式时，如果文件类型匹配，则恢复之前的输入法状态。
--
-- 依赖:
-- - Windows/WSL: 需要 `im-select-mspy.exe`，来自 https://github.com/fengwk/im-select-mspy
-- - Linux: 需要 `fcitx5-remote`
--]]
local utils = require "fengwk.utils"

local M = {}

-- 默认配置
M.config = {
  -- 在进入插入模式时，需要自动恢复输入法状态的文件类型。
  -- 对于其他文件类型，离开插入模式时总会切换到英文。
  active_filetypes = { "markdown" },
  -- 节流超时时间 (毫秒)，用于防止过于频繁地切换输入法。
  throttle_timeout = 100,
}

-- 用于记录离开插入模式时的输入法状态
local fcitx5_last_state = nil
local mspy_last_state = nil

-- im-select-mspy.exe 路径及英文模式标识
local mspy_exe = vim.fs.joinpath(vim.fn.stdpath("config"), "lib", "im-select-mspy.exe")
local MSPY_ENGLISH_MODE = "英语模式"

-- fcitx5 状态缓存，避免频繁调用外部命令
local fcitx5_state_cache = nil
local fcitx5_state_cache_last_read = 0
local state_cache_timeout_ns = 100 * 1e6 -- 100 毫秒

-- fcitx5-remote 命令返回 "1" 代表非激活 (英文)，"2" 代表激活
local Fcitx5State = {
  INACTIVE = "1",
  ACTIVE = "2",
}

-- 读取当前的 fcitx5 状态 (带缓存)
local function read_fcitx5_state()
  local cur_nanos = vim.uv.hrtime()
  if fcitx5_state_cache and (cur_nanos < fcitx5_state_cache_last_read + state_cache_timeout_ns) then
    return fcitx5_state_cache
  end

  local state = utils.system { "fcitx5-remote" }
  if type(state) == "string" then
    state = vim.trim(state)
  end

  fcitx5_state_cache = state
  fcitx5_state_cache_last_read = cur_nanos
  return state
end

-- 自动切换 fcitx5 输入法
-- @param mode "in" 表示进入插入/选择模式, "out" 表示离开
local function auto_switch_fcitx5(mode)
  if mode == "in" then -- 进入插入模式
    -- 如果离开插入模式前输入法是激活状态，则恢复它
    if fcitx5_last_state == Fcitx5State.ACTIVE then
      utils.system { "fcitx5-remote", "-o" } -- 激活输入法
    end
  else -- 离开插入模式
    local state = read_fcitx5_state()
    fcitx5_last_state = state
    -- 如果输入法当前是激活状态，则关闭它 (切换到英文)
    if state ~= Fcitx5State.INACTIVE then
      utils.system { "fcitx5-remote", "-c" } -- 关闭输入法
    end
  end
end

-- 异步切换 Windows/WSL 的微软拼音输入法
-- 依赖外部工具 `im-select-mspy.exe`
-- 离开插入模式时：异步获取当前状态并切换到英文。
-- 进入插入模式时：若之前为中文则异步恢复。
-- @param mode "in" 表示进入插入/选择模式, "out" 表示离开
local function auto_switch_mspy(mode)
  if mode == "in" then
    if mspy_last_state and mspy_last_state ~= MSPY_ENGLISH_MODE then
      vim.system({ mspy_exe, mspy_last_state }, {}, function() end)
    end
  else -- "out"
    vim.system({ mspy_exe }, { text = true }, function(obj)
      if obj.code == 0 and obj.stdout then
        local state = vim.trim(obj.stdout)
        if state ~= "" then
          mspy_last_state = state
          if state ~= MSPY_ENGLISH_MODE then
            vim.system({ mspy_exe, MSPY_ENGLISH_MODE }, {}, function() end)
          end
        end
      end
    end)
  end
end

-- 根据操作系统分发输入法切换任务
-- @param mode "in" 表示进入插入/选择模式, "out" 表示离开
local function auto_switch_im(mode)
  if utils.os == "win" or utils.os == "wsl" then
    auto_switch_mspy(mode)
  else -- 默认为使用 fcitx5 的 Linux/macOS
    auto_switch_fcitx5(mode)
  end
end

-- 进入插入/选择模式时的回调函数
local function on_insert_enter()
  local ft = vim.bo.filetype
  if vim.tbl_contains(M.config.active_filetypes, ft) then
    auto_switch_im("in")
  end
end

-- 离开插入/选择模式，进入普通模式时的回调函数
local function on_normal_enter()
  auto_switch_im("out")
end

-- 仅在离开插入/选择模式回到普通模式时切换回英文。
-- 避免 Visual -> Normal 这类场景误触发 Windows/WSL 输入法切换。
local function on_mode_changed_to_normal(ev)
  local match = ev and ev.match or ""
  local old_mode, new_mode = string.match(match, "^(.-):(.-)$")
  if new_mode ~= "n" or old_mode == nil or old_mode == "" then
    return
  end

  local old_mode_head = string.sub(old_mode, 1, 1)
  if old_mode_head == "i" or old_mode_head == "s" or old_mode_head == "S" then
    on_normal_enter()
  end
end

-- 为 on_focus_gained 创建一个闭包，以便传递节流后的 on_normal_enter
local function create_on_focus_gained(normal_enter_cb)
  return function()
    -- 检查当前是否为普通模式
    if vim.fn.mode() == "n" then
      normal_enter_cb()
    end
  end
end

-- 插件初始化函数
function M.setup(user_config)
  -- 合并用户配置和默认配置
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

  -- 创建经过节流优化的回调函数
  local timeout = M.config.throttle_timeout
  local throttled_on_insert_enter = utils.throttle(on_insert_enter, timeout)
  local throttled_on_mode_changed_to_normal = utils.throttle(on_mode_changed_to_normal, timeout)
  local throttled_on_normal_enter = utils.throttle(on_normal_enter, timeout)
  local on_focus_gained = create_on_focus_gained(throttled_on_normal_enter)

  -- 设置自动命令以触发输入法切换
  local group = vim.api.nvim_create_augroup("user_im_auto_switch", { clear = true })

  -- 进入插入或选择模式时切换输入法
  vim.api.nvim_create_autocmd(
    { "InsertEnter" },
    { group = group, pattern = "*", callback = throttled_on_insert_enter }
  )
  vim.api.nvim_create_autocmd(
    { "ModeChanged" },
    { group = group, pattern = "*:[sS]*", callback = throttled_on_insert_enter }
  )

  -- 进入普通模式时切换回英文
  vim.api.nvim_create_autocmd(
    { "ModeChanged" },
    { group = group, pattern = "*:n", callback = throttled_on_mode_changed_to_normal }
  )

  -- 仅在使用 fcitx5 的 Linux/macOS 上，在启动完成后与重新获得焦点时校正普通模式输入法状态。
  -- WSL 走的是 Windows 输入法切换链路，FocusGained 上再次触发“out”会与
  -- Windows 的窗口级输入法状态恢复互相干扰，导致重新聚焦时出现反向切换。
  if utils.os ~= "win" and utils.os ~= "wsl" then
    vim.api.nvim_create_autocmd(
      { "VimEnter", "FocusGained" },
      { group = group, pattern = "*", callback = on_focus_gained }
    )
  end
end

return M
