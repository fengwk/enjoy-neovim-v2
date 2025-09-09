local utils = require("telescope._extensions.utils")
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require "telescope.config".values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"
local bookmarks = require "fengwk.custom.bookmarks"

-- 用于存储 setup 时传入的选项
local setup_opts = {}

-- 定义每个条目在 Telescope 列表中的显示方式
local function display_func(item)
  local displayer = entry_display.create {
    separator = " │ ", -- 使用更美观的分隔符
    items = {
      { width = 40 },
      { width = 5,       align = "right" },
      { remaining = true },
    },
  }

  return displayer {
    -- item.value 是 entry_maker_func 中返回的原始书签对象
    { item.value.annotation,                         "Comment" },
    { item.value.row,                                "Line" },
    { vim.fn.fnamemodify(item.value.filename, ":~"), "Path" }, -- 使用相对路径，更简洁
  }
end

-- 将从 bookmarks.list_marks() 获取的原始数据转换为 Telescope 可用的格式
local function entry_maker_func(entry)
  return {
    value = entry,
    ordinal = entry.annotation .. " " .. entry.filename, -- 用于搜索的字符串，包含注释和文件名
    display = display_func,
    -- 以下字段供 previewer 使用
    filename = entry.filename,
    lnum = entry.row,
  }
end

-- Action: 打开书签
local function open_mark(prompt_bufnr, before_open)
  local selected = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if selected then
    -- 如果提供了 before_open 回调 (例如用于分屏)，则先执行它
    if before_open then
      before_open()
    end
    -- 关键修改：使用 .id 而不是 .hash
    bookmarks.open_mark(selected.value.id)
  end
end

-- Action: 移除书签
local function remove_mark(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  -- Telescope 的标准删除流程
  current_picker:delete_selection(function(selection)
    -- 关键修改：使用 .id 而不是 .hash
    bookmarks.remove_mark_item(selection.value.id)
  end)
end

-- 创建并启动 Telescope Picker 的主函数
local function bookmarks_picker(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend("force", {}, conf, setup_opts, opts)

  pickers.new(opts, {
    prompt_title = "Bookmarks",
    -- finder 从 bookmarks 模块获取数据
    finder = finders.new_table {
      results = bookmarks.list_marks(),
      entry_maker = entry_maker_func,
    },
    -- sorter 使用 Telescope 的通用排序器
    sorter = conf.generic_sorter(opts),
    -- previewer 使用 qflist 预览器，它会自动利用 filename 和 lnum
    previewer = conf.qflist_previewer(opts),
    -- 绑定自定义快捷键
    attach_mappings = function(prompt_bufnr, map)
      utils.map_preview(map)
      utils.map_select_one(map, open_mark)
      map({ "n" }, "dd", remove_mark)
      map({ "i", "n" }, "<C-x>", function() open_mark(prompt_bufnr, function() vim.cmd("sp") end) end)
      map({ "i", "n" }, "<C-v>", function() open_mark(prompt_bufnr, function() vim.cmd("vsp") end) end)
      map({ "i", "n" }, "<C-t>", function() open_mark(prompt_bufnr, function() vim.cmd("tabnew") end) end)
      -- 返回 true 表示不加载 Telescope 的默认映射
      return true
    end,
  }):find()
end

-- 注册为 Telescope 扩展
return require("telescope").register_extension {
  setup = function(opts)
    if opts and #opts >= 1 then
      setup_opts = opts[1]
    end
  end,
  exports = {
    bookmarks = bookmarks_picker,
  },
}
