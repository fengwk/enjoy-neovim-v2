local M = {}

local utils = require "fengwk.utils"

-- 本模块提供一个极简的 review comment 能力：
-- 1. 使用文件绝对路径的 hash 在 stdpath("state") 下持久化 JSON
-- 2. 使用 extmark 在 buffer 中渲染虚拟标记与下划线高亮
-- 3. 使用 line + col + origin_text 作为最小定位信息
-- 4. 当文本发生变化时尝试重定位，无法唯一恢复时暂时隐藏 comment

-- 所有渲染都复用同一个 namespace，便于统一清理与重绘。
local namespace = vim.api.nvim_create_namespace "fengwk_review_comments"
-- 所有自动命令都放在独立 augroup 中，避免重复注册。
local group = vim.api.nvim_create_augroup("fengwk_review_comments", { clear = true })

-- initialized 用于保证 setup 只执行一次。
local initialized = false
-- cache 以绝对路径为 key 缓存已加载的文件状态，减少重复读盘。
local cache = {}
-- refresh_timers 为每个 buffer 保存一个防抖定时器，避免高频编辑时重复全量解析。
local refresh_timers = {}
-- hover_win 记录当前浮窗，便于在移动光标或离开 buffer 时关闭。
local hover_win = nil
-- hover_key 标识当前浮窗对应的 comment 集合，用于避免重复重建浮窗。
local hover_key = nil
-- 图标在非 TTY 环境下使用 Nerd Font 字形，在 TTY 中回退为 ASCII 字符。
local comment_icon = utils.is_tty() and "@" or "󰍩"

-- 统一的通知函数，避免在各处重复指定默认等级。
local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

-- 将路径展开为绝对路径，避免存储层与比较逻辑受到相对路径影响。
local function normalize_path(path)
  return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

-- 将多行文本拆成数组，供定位、导出与浮窗展示复用。
local function split_lines(text)
  return vim.split(text or "", "\n", { plain = true })
end

-- 获取 buffer 对应的绝对文件路径；无文件 buffer 返回 nil。
local function get_buffer_file(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return nil
  end
  return normalize_path(file)
end

-- 当前实现按“文件”持久化，而不是按项目持久化。
-- 文件名直接使用绝对路径的 sha256，避免状态目录下出现复杂路径层级。
local function get_state_file(file)
  local base = normalize_path(vim.fn.stdpath "state") .. "/review-comments"
  return string.format("%s/%s.json", base, vim.fn.sha256(file))
end

-- 从磁盘读取 JSON；不存在或空文件都视为无状态。
local function read_json(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read "*a"
  file:close()

  if not content or content == "" then
    return nil
  end

  local ok, decoded = pcall(vim.fn.json_decode, content)
  if not ok or type(decoded) ~= "table" then
    notify("Failed to parse review comment JSON: " .. path, vim.log.levels.ERROR)
    return nil
  end

  return decoded
end

-- 使用“先写临时文件再 rename”的方式原子写入，避免中途失败导致 JSON 损坏。
local function write_json_atomic(path, data)
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")

  local tmp = path .. ".tmp"
  local file = io.open(tmp, "w")
  if not file then
    notify("Failed to write review comments: " .. tmp, vim.log.levels.ERROR)
    return false
  end

  file:write(vim.fn.json_encode(data))
  file:close()

  if vim.uv.fs_rename(tmp, path) then
    return true
  end

  notify("Failed to write review comments: " .. path, vim.log.levels.ERROR)
  return false
end

-- 当一个文件没有任何 comment 时，直接删除对应的状态文件，保持状态目录干净。
local function delete_state_file(file)
  local path = get_state_file(file)
  if vim.uv.fs_stat(path) then
    local ok, err = vim.uv.fs_unlink(path)
    if not ok then
      notify("Failed to delete review comments: " .. (err or path), vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

-- 排序规则只关注定位稳定性：先按行，再按列，最后按 id 保证结果稳定。
local function sort_comments(comments)
  table.sort(comments, function(a, b)
    if a.line ~= b.line then
      return a.line < b.line
    end
    if a.col ~= b.col then
      return a.col < b.col
    end
    return a.id < b.id
  end)
end

-- 加载某个文件的状态：
-- 1. 优先使用内存缓存
-- 2. 回退到 JSON 文件
-- 3. 只接受最小必需字段齐全的 comment 记录
local function load_state(file)
  local state = cache[file]
  if state then
    return state
  end

  local decoded = read_json(get_state_file(file))
  local comments = {}

  if decoded and type(decoded.comments) == "table" then
    for _, item in ipairs(decoded.comments) do
      if type(item) == "table" and item.file and item.line and item.col and item.origin_text and item.comment then
        table.insert(comments, {
          id = tostring(item.id or vim.uv.hrtime()),
          file = normalize_path(tostring(item.file)),
          line = tonumber(item.line) or 1,
          col = tonumber(item.col) or 1,
          origin_text = tostring(item.origin_text),
          comment = tostring(item.comment),
        })
      end
    end
  end

  sort_comments(comments)
  state = { file = file, comments = comments, resolved_comments = nil, unresolved_count = 0, last_tick = nil }
  cache[file] = state
  return state
end

-- 保存状态时只做两种结果：
-- 1. comment 为空：删除 JSON 文件
-- 2. comment 非空：完整重写 JSON 文件
local function save_state(file)
  local state = load_state(file)
  sort_comments(state.comments)

  if #state.comments == 0 then
    return delete_state_file(file)
  end

  return write_json_atomic(get_state_file(file), {
    version = 1,
    file = file,
    comments = state.comments,
  })
end

-- 读取单行文本，是后续范围提取和定位比较的基础工具。
local function get_line_text(bufnr, line)
  local lines = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)
  return lines[1] or ""
end

-- 从给定锚点提取当前 buffer 中的文本，长度与 origin_text 对齐。
-- 该函数不会做模糊匹配，只负责“按旧坐标切片”。
local function get_text_at_anchor(bufnr, line, col, origin_text)
  local origin_lines = split_lines(origin_text)
  if #origin_lines == 0 then
    return nil
  end

  if line < 1 or line > vim.api.nvim_buf_line_count(bufnr) then
    return nil
  end

  if #origin_lines == 1 then
    local current_line = get_line_text(bufnr, line)
    return current_line:sub(col, col + #origin_lines[1] - 1)
  end

  local end_line = line + #origin_lines - 1
  if end_line > vim.api.nvim_buf_line_count(bufnr) then
    return nil
  end

  local parts = {}
  for index = 1, #origin_lines do
    local current_line = get_line_text(bufnr, line + index - 1)
    if index == 1 then
      table.insert(parts, current_line:sub(col))
    elseif index == #origin_lines then
      table.insert(parts, current_line:sub(1, #origin_lines[index]))
    else
      table.insert(parts, current_line)
    end
  end

  return table.concat(parts, "\n")
end

-- 判断指定坐标处的实际文本是否仍然与原始文本一致。
local function match_origin_at(bufnr, line, col, origin_text)
  return get_text_at_anchor(bufnr, line, col, origin_text) == origin_text
end

-- 在整个文件内搜索 origin_text 的所有候选位置。
-- 搜索策略很简单：先找首行出现位置，再用完整 origin_text 做二次确认。
local function find_candidates(bufnr, origin_text)
  local candidates = {}
  local origin_lines = split_lines(origin_text)
  local first_line = origin_lines[1]
  if not first_line or first_line == "" then
    return candidates
  end

  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for row, line in ipairs(all_lines) do
    local start_at = 1
    while true do
      local col = line:find(first_line, start_at, true)
      if not col then
        break
      end

      if match_origin_at(bufnr, row, col, origin_text) then
        table.insert(candidates, { line = row, col = col })
      end

      start_at = col + 1
    end
  end

  return candidates
end

-- 解析单条 comment 的当前位置：
-- 1. 先尝试旧坐标直接命中
-- 2. 再尝试全文件搜索 origin_text
-- 3. 使用离旧 line/col 最近的候选
-- 4. 如果最近候选不唯一，则视为冲突并放弃该 comment
local function resolve_comment(bufnr, comment)
  if match_origin_at(bufnr, comment.line, comment.col, comment.origin_text) then
    return vim.tbl_extend("force", {}, comment)
  end

  local candidates = find_candidates(bufnr, comment.origin_text)
  if #candidates == 0 then
    return false
  end

  local best = nil
  local best_score = nil
  local ambiguous = false

  for _, candidate in ipairs(candidates) do
    local score = math.abs(candidate.line - comment.line) * 100000 + math.abs(candidate.col - comment.col)
    if not best_score or score < best_score then
      best = candidate
      best_score = score
      ambiguous = false
    elseif score == best_score then
      ambiguous = true
    end
  end

  if not best or ambiguous then
    return nil
  end

  return vim.tbl_extend("force", {}, comment, {
    line = best.line,
    col = best.col,
  })
end

-- 对当前 buffer 的全部 comment 做一次解析，但不会修改原始 comment 列表。
-- 解析结果只缓存到 resolved_comments 中，失配 comment 仅在展示与导出时跳过。
local function resolve_buffer_comments(bufnr)
  local file = get_buffer_file(bufnr)
  if not file then
    return nil, nil
  end

  local state = load_state(file)
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)

  if state.resolved_comments and state.last_tick == tick then
    return file, state
  end

  local resolved = {}
  local unresolved_count = 0

  for _, comment in ipairs(state.comments) do
    local resolved_comment = resolve_comment(bufnr, comment)
    if resolved_comment then
      table.insert(resolved, resolved_comment)
    else
      unresolved_count = unresolved_count + 1
    end
  end

  sort_comments(resolved)
  state.resolved_comments = resolved
  state.unresolved_count = unresolved_count
  state.last_tick = tick
  return file, state
end

-- 获取缓存中的解析结果。
-- 当 refresh=false 时不会触发新的全量解析，适合 CursorMoved 这类高频场景。
local function get_resolved_state(bufnr, refresh)
  local file = get_buffer_file(bufnr)
  if not file then
    return nil, nil
  end

  local state = load_state(file)
  if refresh or not state.resolved_comments then
    return resolve_buffer_comments(bufnr)
  end

  return file, state
end

-- 根据 origin_text 计算 comment 作用范围的结束位置。
local function get_comment_end(comment)
  local origin_lines = split_lines(comment.origin_text)
  if #origin_lines == 1 then
    return comment.line, comment.col + #origin_lines[1] - 1
  end
  return comment.line + #origin_lines - 1, #origin_lines[#origin_lines]
end

-- 判断光标是否命中 comment 对应范围。
-- 这里统一把所有 comment 视为连续文本范围；<C-v> 已在录入时降级为多行整段文本。
local function comment_contains(comment, row, col)
  local end_line, end_col = get_comment_end(comment)

  if row < comment.line or row > end_line then
    return false
  end

  if comment.line == end_line then
    return col >= comment.col and col <= end_col
  end

  if row == comment.line then
    return col >= comment.col
  end

  if row == end_line then
    return col <= end_col
  end

  return true
end

-- 获取当前光标命中的所有 comment。
-- 如果同一位置存在多条 comment，则后续由 UI 进行选择或批量展示。
local function get_comments_at_cursor(bufnr)
  local _, state = get_resolved_state(bufnr, false)
  if not state then
    return nil, {}
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2] + 1
  local comments = {}

  for _, comment in ipairs(state.resolved_comments or {}) do
    if comment_contains(comment, row, col) then
      table.insert(comments, comment)
    end
  end

  return state, comments
end

-- 关闭 hover 浮窗；重复调用是安全的。
local function close_hover()
  if hover_win and vim.api.nvim_win_is_valid(hover_win) then
    vim.api.nvim_win_close(hover_win, true)
  end
  hover_win = nil
  hover_key = nil
end

-- 为当前命中的 comment 集合生成稳定 key，用于判断 hover 是否需要重建。
local function get_hover_key(comments)
  local ids = {}
  for _, comment in ipairs(comments) do
    table.insert(ids, comment.id)
  end
  table.sort(ids)
  return table.concat(ids, ",")
end

-- 将现有 hover 浮窗重新定位到当前光标附近。
-- 这样在同一条 comment 范围内移动时，不需要销毁并重建浮窗。
local function reposition_hover()
  if not hover_win or not vim.api.nvim_win_is_valid(hover_win) then
    return false
  end

  return pcall(vim.api.nvim_win_set_config, hover_win, {
    relative = "cursor",
    row = 1,
    col = 0,
  })
end

-- 根据当前状态重绘 buffer：
-- 1. 清空旧 extmark
-- 2. 给 comment 范围加下划线
-- 3. 在起始行的行尾绘制虚拟标记
local function render_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local _, state = resolve_buffer_comments(bufnr)
  if not state then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  local line_counts = {}
  for _, comment in ipairs(state.resolved_comments or {}) do
    line_counts[comment.line] = (line_counts[comment.line] or 0) + 1

    local end_line, end_col = get_comment_end(comment)
    vim.api.nvim_buf_set_extmark(bufnr, namespace, comment.line - 1, math.max(comment.col - 1, 0), {
      end_row = end_line - 1,
      end_col = math.max(end_col, 0),
      hl_group = "ReviewCommentUnderline",
      priority = 90,
    })
  end

  for line, _ in pairs(line_counts) do
    vim.api.nvim_buf_set_extmark(bufnr, namespace, line - 1, 0, {
      sign_text = comment_icon,
      sign_hl_group = "ReviewCommentMarker",
      priority = 100,
    })
  end
end

-- 根据当前模式构造待新增的 comment：
-- 1. 普通模式：默认取整行
-- 2. v 模式：取精确字符范围
-- 3. V 与 <C-v>：统一简化为多行整段文本
local function build_selection(bufnr, opts)
  local file = get_buffer_file(bufnr)
  if not file then
    return nil, "Current buffer has no file path"
  end

  if opts and opts.range > 0 then
    local mode = vim.fn.visualmode()
    local start_pos = vim.fn.getpos "'<"
    local end_pos = vim.fn.getpos "'>"
    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    if start_line == 0 or end_line == 0 then
      return nil, "No valid selection range found"
    end

    if start_line > end_line or (start_line == end_line and start_col > end_col) then
      start_line, end_line = end_line, start_line
      start_col, end_col = end_col, start_col
    end

    if mode == "V" or mode == "\022" then
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
      local origin_text = table.concat(lines, "\n")
      if origin_text == "" then
        return nil, "Selection is empty"
      end
      return {
        id = tostring(vim.uv.hrtime()),
        file = file,
        line = start_line,
        col = 1,
        origin_text = origin_text,
      }
    end

    if vim.o.selection == "exclusive" then
      end_col = math.max(end_col - 1, start_col)
    end

    local lines = vim.api.nvim_buf_get_text(bufnr, start_line - 1, start_col - 1, end_line - 1, end_col, {})
    local origin_text = table.concat(lines, "\n")
    if origin_text == "" then
      return nil, "Selection is empty"
    end

    return {
      id = tostring(vim.uv.hrtime()),
      file = file,
      line = start_line,
      col = start_col,
      origin_text = origin_text,
    }
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local origin_text = get_line_text(bufnr, line)
  if origin_text == "" then
    return nil, "Current line is empty"
  end

  return {
    id = tostring(vim.uv.hrtime()),
    file = file,
    line = line,
    col = 1,
    origin_text = origin_text,
  }
end

-- 生成多 comment 选择器中的单条展示文本。
local function format_comment_label(comment)
  local first = comment.comment:gsub("\n.*", "")
  return string.format("L%d:C%d | %s", comment.line, comment.col, first)
end

-- 当一个位置存在多条 comment 时，交给 vim.ui.select 选择具体对象。
local function select_comment(callback)
  local bufnr = vim.api.nvim_get_current_buf()
  resolve_buffer_comments(bufnr)
  local state, comments = get_comments_at_cursor(bufnr)
  if not state or #comments == 0 then
    notify("No review comment under cursor", vim.log.levels.WARN)
    return
  end

  if #comments == 1 then
    callback(state, comments[1])
    return
  end

  vim.ui.select(comments, {
    prompt = "Choose a comment:",
    format_item = format_comment_label,
  }, function(choice)
    if choice then
      callback(state, choice)
    end
  end)
end

-- hover 浮窗只展示 comment 内容本身，避免干扰阅读。
local function open_comment_float(comments)
  if #comments == 0 then
    close_hover()
    return
  end

  local next_hover_key = get_hover_key(comments)
  if hover_key == next_hover_key and hover_win and vim.api.nvim_win_is_valid(hover_win) then
    reposition_hover()
    return
  end

  close_hover()

  local lines = {}
  for index, comment in ipairs(comments) do
    if index > 1 then
      table.insert(lines, "")
      table.insert(lines, "---")
      table.insert(lines, "")
    end
    for _, line in ipairs(split_lines(comment.comment)) do
      table.insert(lines, line)
    end
  end

  local _, win = vim.lsp.util.open_floating_preview(lines, "markdown", {
    border = "rounded",
    focusable = false,
    close_events = { "CursorMovedI", "InsertEnter", "BufHidden", "BufLeave" },
  })
  hover_win = win
  hover_key = next_hover_key
end

-- 根据当前光标位置刷新 hover；未命中 comment 时主动关闭浮窗。
local function refresh_hover(bufnr)
  if vim.bo[bufnr].buftype ~= "" then
    close_hover()
    return
  end

  local _, comments = get_comments_at_cursor(bufnr)
  if #comments == 0 then
    close_hover()
    return
  end

  open_comment_float(comments)
end

-- 将 comment 的起止行格式化为导出标签。
-- 所有行号都基于 Neovim 的 1-based 坐标体系。
local function format_export_line_label(comment)
  local end_line = select(1, get_comment_end(comment))
  if comment.line == end_line then
    return string.format("Line %d", comment.line)
  end
  return string.format("Line %d-%d", comment.line, end_line)
end

-- 获取当前 buffer 的导出上下文，供 export 与组合命令复用。
local function get_export_context(bufnr)
  local file, state = resolve_buffer_comments(bufnr)
  local resolved_comments = state and state.resolved_comments or {}
  return file, state, resolved_comments
end

-- 跳转到当前文件中的上一个/下一个可解析 review comment。
local function jump_comment(direction)
  local bufnr = vim.api.nvim_get_current_buf()
  local file, state = resolve_buffer_comments(bufnr)
  local comments = state and state.resolved_comments or {}
  if not file or #comments == 0 then
    notify("No review comments for current file", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2] + 1
  local target = nil

  if direction > 0 then
    for _, comment in ipairs(comments) do
      if comment.line > row or (comment.line == row and comment.col > col) then
        target = comment
        break
      end
    end
  else
    for index = #comments, 1, -1 do
      local comment = comments[index]
      if comment.line < row or (comment.line == row and comment.col < col) then
        target = comment
        break
      end
    end
  end

  if not target then
    notify(direction > 0 and "No next review comment" or "No previous review comment", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_win_set_cursor(0, { target.line, math.max(target.col - 1, 0) })
  refresh_hover(bufnr)
end

-- 按 id 删除 comment，返回是否删除成功。
local function remove_comment(state, comment_id)
  for index, comment in ipairs(state.comments) do
    if comment.id == comment_id then
      table.remove(state.comments, index)
      return true
    end
  end
  return false
end

-- 停止并释放某个 buffer 的刷新定时器。
local function stop_refresh_timer(bufnr)
  local timer = refresh_timers[bufnr]
  if not timer then
    return
  end

  refresh_timers[bufnr] = nil
  timer:stop()
  timer:close()
end

-- 在编辑后异步重算解析结果并重绘。
-- 这里使用简单防抖，避免每次 TextChanged 都立即扫描整个文件。
local function schedule_render(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end

  stop_refresh_timer(bufnr)

  local timer = vim.uv.new_timer()
  refresh_timers[bufnr] = timer
  timer:start(120, 0, vim.schedule_wrap(function()
    if refresh_timers[bufnr] == timer then
      refresh_timers[bufnr] = nil
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
      if not timer:is_closing() then timer:close() end
      return
    end

    render_buffer(bufnr)
    if bufnr == vim.api.nvim_get_current_buf() then
      refresh_hover(bufnr)
    end

    if not timer:is_closing() then timer:close() end
  end))
end

-- 新增 comment：先采集选区，再询问 comment 文本，最后保存并重绘。
function M.add(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local selection, err = build_selection(bufnr, opts)
  if not selection then
    notify(err, vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Review comment: " }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end

    local state = load_state(selection.file)
    selection.comment = vim.trim(input)
    table.insert(state.comments, selection)
    state.resolved_comments = nil
    state.last_tick = nil
    sort_comments(state.comments)
    save_state(selection.file)
    render_buffer(bufnr)
  end)
end

-- 删除当前光标命中的 comment。
function M.delete()
  select_comment(function(state, comment)
    if remove_comment(state, comment.id) then
      state.resolved_comments = nil
      state.last_tick = nil
      save_state(state.file)
      render_buffer(vim.api.nvim_get_current_buf())
    end
  end)
end

-- 编辑当前光标命中的 comment 文本；不改变定位信息。
function M.edit()
  select_comment(function(state, comment)
    vim.ui.input({ prompt = "Edit review comment: ", default = comment.comment }, function(input)
      if not input or vim.trim(input) == "" then
        return
      end

      comment.comment = vim.trim(input)
      state.resolved_comments = nil
      state.last_tick = nil
      save_state(state.file)
      render_buffer(vim.api.nvim_get_current_buf())
    end)
  end)
end

-- 清空当前文件的全部 comment；清空后会删除对应 JSON 文件。
function M.clear(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local file = get_buffer_file(bufnr)
  if not file then
    if not opts.silent_warn then
      notify("Current buffer has no file path", vim.log.levels.WARN)
    end
    return false
  end

  local state = load_state(file)
  if #state.comments == 0 then
    if not opts.silent_warn then
      notify("No review comments for current file", vim.log.levels.WARN)
    end
    return false
  end

  state.comments = {}
  state.resolved_comments = {}
  state.unresolved_count = 0
  state.last_tick = nil
  save_state(file)
  render_buffer(bufnr)
  return true
end

-- 导出当前文件的全部 comment，格式固定为便于复制给外部 agent 的块结构。
function M.export(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local file, state, resolved_comments = get_export_context(bufnr)
  if not file then
    if not opts.silent_warn then
      notify("Current buffer has no file path", vim.log.levels.WARN)
    end
    return false
  end

  if not state or #state.comments == 0 then
    if not opts.silent_warn then
      notify("No review comments for current file", vim.log.levels.WARN)
    end
    return false
  end

  if #resolved_comments == 0 then
    if not opts.silent_warn then
      notify("No exportable review comments for current file", vim.log.levels.WARN)
    end
    return false
  end

  local lines = {
    string.format("File: %s", file),
    "",
  }

  for index, comment in ipairs(resolved_comments) do
    if index > 1 then
      table.insert(lines, "---")
      table.insert(lines, "")
    end
    table.insert(lines, string.format("Selected Text, %s", format_export_line_label(comment)))
    table.insert(lines, "```")
    for _, line in ipairs(split_lines(comment.origin_text)) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
    table.insert(lines, "")
    table.insert(lines, "User Comment")
    table.insert(lines, "```")
    for _, line in ipairs(split_lines(comment.comment)) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  local content = table.concat(lines, "\n")
  vim.fn.setreg('"', content)
  vim.fn.setreg("+", content)
  vim.fn.setreg("*", content)
  if state.unresolved_count > 0 then
    notify(string.format("Review comments exported to clipboard (%d unresolved comments skipped)", state.unresolved_count), vim.log.levels.WARN)
  end
  return true
end

-- setup 负责注册命令、定义高亮和自动命令。
function M.setup()
  if initialized then
    return
  end
  initialized = true

  -- 行尾标记使用较弱的提示色；原文范围沿用 DiagnosticInfo 的颜色并额外添加 undercurl。
  vim.api.nvim_set_hl(0, "ReviewCommentMarker", { link = "DiagnosticHint", default = true })
  local diagnostic_info = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo", link = false })
  local underline_hl = { undercurl = true, default = true }
  if diagnostic_info.fg then
    underline_hl.fg = diagnostic_info.fg
    underline_hl.sp = diagnostic_info.fg
  end
  vim.api.nvim_set_hl(0, "ReviewCommentUnderline", underline_hl)

  vim.api.nvim_create_user_command("ReviewCommentsAdd", function(opts)
    M.add(opts)
  end, { range = true, desc = "Add review comment" })

  vim.api.nvim_create_user_command("ReviewCommentsDelete", function()
    M.delete()
  end, { desc = "Delete review comment at cursor" })

  vim.api.nvim_create_user_command("ReviewCommentsEdit", function()
    M.edit()
  end, { desc = "Edit review comment at cursor" })

  vim.api.nvim_create_user_command("ReviewCommentsCopy", function()
    M.export()
  end, { desc = "Copy current file review comments" })

  vim.api.nvim_create_user_command("ReviewCommentsCopyAndClear", function()
    M.export()
    M.clear { silent_warn = true }
  end, { desc = "Copy and then clear current file review comments" })

  vim.api.nvim_create_user_command("ReviewCommentsClear", function()
    M.clear()
  end, { desc = "Clear current file review comments" })

  vim.keymap.set("n", "]r", function()
    jump_comment(1)
  end, { desc = "Next review comment" })

  vim.keymap.set("n", "[r", function()
    jump_comment(-1)
  end, { desc = "Previous review comment" })

  -- 进入文件或保存文件后重绘，可确保外部修改后的定位与标记保持同步。
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].buftype == "" then
        stop_refresh_timer(args.buf)
        render_buffer(args.buf)
      end
    end,
  })

  -- 文本变化后异步重算解析结果，避免在高频光标移动时执行全文件扫描。
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args)
      schedule_render(args.buf)
    end,
  })

  -- 光标停留或移动时只读取缓存中的解析结果，用于轻量 hover 展示。
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorMoved" }, {
    group = group,
    callback = function(args)
      refresh_hover(args.buf)
    end,
  })

  -- 进入插入模式或离开 buffer 时关闭 hover，减少视觉干扰。
  vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertEnter", "BufLeave" }, {
    group = group,
    callback = close_hover,
  })

  -- buffer 被销毁时回收定时器，避免悬挂句柄。
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    group = group,
    callback = function(args)
      stop_refresh_timer(args.buf)
      close_hover()
    end,
  })
end

return M
