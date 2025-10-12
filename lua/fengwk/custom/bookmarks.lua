local M = {}

local globals = require "fengwk.globals"
local utils = require "fengwk.utils"
local md5 = require "fengwk.custom.md5"

-- 配置文件路径
local data_path = vim.fs.joinpath(vim.fn.stdpath("data"), "bookmarks.json")

-- data_cache 是内存中的单一数据源
local data_cache = nil

-- 插件的默认配置
local config = {
  search_range = 300,
  sign = {
    enabled = true,
    name = "BookmarkSign",
    text = utils.is_tty() and "M" or "🔖",
    texthl = "DiagnosticSignInfo",
  },
}

-- 创建一个防抖的数据写入函数
function M.write_data()
  if data_cache then
    utils.write_json(data_path, data_cache)
  end
end

--- 读取数据
function M.read_data(force)
  if data_cache == nil or force then
    data_cache = utils.read_json(data_path) or {}
  end
  return data_cache
end

-- 更新指定缓冲区的所有行号标记
M.update_signs = utils.debounce(function(bufnr)
  if not config.sign.enabled then
    return
  end
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- 清空本组旧 sign
  vim.fn.sign_unplace("user_bookmark_sign", { buffer = bufnr })

  -- 根据 data 放置新 sign
  local data = M.read_data()
  local current_buf_filename = vim.api.nvim_buf_get_name(bufnr)
  for _, mark_item in pairs(data) do
    if mark_item.filename == current_buf_filename then
      local real_row = M.find_real_row(mark_item)
      if real_row >= 1 then
        vim.fn.sign_place(0, "user_bookmark_sign", config.sign.name, bufnr, { lnum = real_row })
      end
    end
  end
end, 250)

--- 生成一个唯一的书签标识符
local function generate_bookmark_id(filename, line_content)
  local combine = filename .. "<|>" .. vim.trim(line_content)
  return md5.sumhexa(combine)
end

--- 添加一个书签
function M.add_mark(annotation)
  if globals.is_special_ft() then
    vim.notify("Current file type does not support bookmarks", vim.log.levels.WARN)
    return
  end
  local filename = vim.fn.expand("%:p")
  if utils.is_uri(filename) then
    vim.notify("Remote files or URIs do not support bookmarks", vim.log.levels.WARN)
    return
  end
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local current_line = vim.api.nvim_get_current_line()
  local id = generate_bookmark_id(filename, current_line)
  local data = M.read_data(true)
  if data[id] then
    vim.notify("Bookmark already exists for this line", vim.log.levels.INFO)
    return
  end
  data[id] = {
    id = id,
    filename = filename,
    annotation = (annotation and #annotation > 0) and annotation or vim.trim(current_line:sub(1, 50)),
    row = row,
    col = 0,
    line_content = current_line,
  }

  data_cache = data

  M.write_data()
  M.update_signs()
  vim.notify("Bookmark added: " .. data[id].annotation)
end

--- 移除当前行的书签
function M.remove_mark()
  local filename = vim.fn.expand("%:p")
  local current_line = vim.api.nvim_get_current_line()
  local id = generate_bookmark_id(filename, current_line)
  M.remove_mark_item(id)
end

--- 根据 ID 移除书签项
function M.remove_mark_item(id)
  if not id then return end
  local data = M.read_data(true)
  if not data[id] then
    vim.notify("Bookmark to be removed not found", vim.log.levels.WARN)
    return
  end
  data[id] = nil

  data_cache = data

  M.write_data()
  M.update_signs()
  vim.notify("Bookmark removed")
end

--- 更新书签的行号
function M.update_mark_row(id, new_row)
  if not id or not new_row then return end
  local data = M.read_data(true)
  if data[id] and data[id].row ~= new_row then
    data[id].row = new_row

    data_cache = data

    M.write_data()
    M.update_signs()
  end
end

--- 查找书签的真实行号
function M.find_real_row(mark_item)
  local buffer_handle = vim.api.nvim_get_current_buf()
  local last_line_idx = vim.api.nvim_buf_line_count(buffer_handle)
  if mark_item.row <= last_line_idx then
    local line_content = vim.api.nvim_buf_get_lines(buffer_handle, mark_item.row - 1, mark_item.row, false)[1]
    if line_content and generate_bookmark_id(mark_item.filename, line_content) == mark_item.id then
      return mark_item.row
    end
  end
  if config.search_range <= 0 then return -1 end
  local start_row = math.max(1, mark_item.row - config.search_range)
  local end_row = math.min(last_line_idx, mark_item.row + config.search_range)
  if start_row >= end_row then return -1 end
  local lines_in_range = vim.api.nvim_buf_get_lines(buffer_handle, start_row - 1, end_row, false)
  for i, line_content in ipairs(lines_in_range) do
    if line_content and generate_bookmark_id(mark_item.filename, line_content) == mark_item.id then
      local real_row = start_row + i - 1
      if real_row ~= mark_item.row then
        M.update_mark_row(mark_item.id, real_row)
      end
      return real_row
    end
  end
  return -1
end

-- 打开指定的书签
function M.open_mark(id)
  if not id then return end
  local data = M.read_data()
  local mark_item = data and data[id]
  if not mark_item then
    vim.notify("Could not find the bookmark", vim.log.levels.ERROR)
    return
  end
  if not utils.exists(mark_item.filename) then
    vim.notify("File for bookmark does not exist: '" .. mark_item.filename .. "'", vim.log.levels.ERROR)
    return
  end
  vim.schedule(function()
    local current_filename = vim.fn.expand("%:p")
    local target_filename = mark_item.filename

    -- 如果不是当前文件，则切换或打开文件
    if current_filename ~= target_filename then
      local bufnr = vim.fn.bufnr(target_filename)
      local success, _
      if bufnr > 0 then
        -- 缓冲区已存在，直接切换
        success, _ = pcall(function()
          vim.cmd("buffer " .. bufnr)
        end)
      else
        -- 缓冲区不存在，打开新文件
        success, _ = pcall(function()
          vim.cmd("edit " .. vim.fn.fnameescape(target_filename))
        end)
      end

      if not success then
        vim.notify("Failed to open file: " .. target_filename, vim.log.levels.ERROR)
        return
      end
    end

    -- 跳转到指定行
    local row = M.find_real_row(mark_item)
    if row > 0 then
      vim.api.nvim_win_set_cursor(0, { row, 0 })
      vim.cmd("normal! zz")
    else
      vim.notify(
        "Bookmark is broken (content may have changed): '" .. mark_item.annotation .. "'",
        vim.log.levels.WARN
      )
      vim.api.nvim_win_set_cursor(0, { mark_item.row, 0 })
    end
  end)
end

-- 列出所有书签
function M.list_marks()
  local list = {}
  local data = M.read_data(true) or {}
  for _, mark_item in pairs(data) do
    table.insert(list, vim.deepcopy(mark_item))
  end
  -- 按照长度和行号排序
  table.sort(list, function(a, b)
    if a.filename ~= b.filename then
      return a.filename < b.filename
    end
    return a.row < b.row
  end)
  return list
end

--- 设置插件命令和配置
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end

  if config.sign.enabled then
    vim.fn.sign_define(config.sign.name, { text = config.sign.text, texthl = config.sign.texthl })
    local group = vim.api.nvim_create_augroup("user_bookmark_sign", { clear = true })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "TextChanged", "InsertLeave" }, {
      group = group,
      callback = function(args)
        local buf = args.buf
        if buf == 0 then
          return
        end
        M.update_signs(buf)
      end,
    })
  end

  -- vim.keymap.set("n", "<leader>mi", function()
  --   M.add_mark(vim.fn.input("Bookmark Annotation (optional): "))
  -- end, { desc = "Insert Bookmark" })
  --
  -- vim.keymap.set("n", "<leader>md", "<Cmd>BookmarkDelete<CR>", { silent = true, desc = "Insert Bookmark" })

  vim.api.nvim_create_user_command("BookmarkAdd", function(args)
    M.add_mark(args.fargs[1])
  end, { nargs = "?", desc = "Add a bookmark, with optional annotation" })

  vim.api.nvim_create_user_command("BookmarkDelete", M.remove_mark, { desc = "Delete the bookmark on the current line" })
end

return M
