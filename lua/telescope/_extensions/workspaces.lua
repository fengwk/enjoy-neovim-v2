local utils = require("telescope._extensions.utils")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope = require("telescope")

local workspaces = require("fengwk.custom.workspaces")

local setup_opts = {}

--- Opens the selected workspace, with an optional function to run before opening.
local function open_ws(prompt_bufnr, before_open)
  local selected = action_state.get_selected_entry()
  actions.close(prompt_bufnr)

  if not selected then
    return
  end

  local ws_path = selected.value
  if ws_path and ws_path ~= "" then
    if before_open then
      before_open()
    end
    workspaces.open(ws_path)
  end
end

--- Deletes the selected workspace from the list and the data file.
local function remove_ws(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:delete_selection(function(selection)
    if selection and selection.value then
      workspaces.remove(selection.value)
    end
  end)
end

local function workspaces_picker(opts)
  -- [[ RESTORED ]] :: 合并默认选项和运行时选项
  -- 优先级: 运行时选项 > setup中设置的默认选项
  opts = vim.tbl_deep_extend("force", setup_opts, opts or {})

  pickers.new(opts, {
    prompt_title = "Workspaces",
    finder = finders.new_table({
      results = workspaces.list(),
      entry_maker = function(entry)
        local display_path = vim.fn.fnamemodify(entry, ":~")
        local basename = vim.fn.fnamemodify(entry, ":t")
        return {
          value = entry,
          ordinal = basename,
          display = string.format("%s   (%s)", basename, display_path),
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      utils.map_select_one(map, open_ws)
      map({ "n" }, "dd", remove_ws)
      map({ "i", "n" }, "<C-x>", function() open_ws(prompt_bufnr, function() vim.cmd("sp") end) end)
      map({ "i", "n" }, "<C-v>", function() open_ws(prompt_bufnr, function() vim.cmd("vsp") end) end)
      map({ "i", "n" }, "<C-t>", function() open_ws(prompt_bufnr, function() vim.cmd("tabnew") end) end)
      return true
    end,
  }):find()
end

return telescope.register_extension({
  setup = function(opts)
    if opts and #opts >= 1 then
      setup_opts = opts[1]
    end
  end,

  exports = {
    workspaces = workspaces_picker,
  },
})
