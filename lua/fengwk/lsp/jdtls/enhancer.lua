local utils = require "fengwk.utils"

local REMOTE_ATTACH_TIMEOUT_MS = 60000
local REMOTE_ATTACH_LISTENER_KEY = "fengwk_java_remote_attach"

local remote_attach_setup = false

local function trim(value)
  if not value then
    return nil
  end
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function get_tag_value(content, tag)
  if not content or not tag then
    return nil
  end
  return trim(content:match("<" .. tag .. ">%s*([^<]+)%s*</" .. tag .. ">"))
end

local function get_jdtls_root_dir()
  local bufnr = vim.api.nvim_get_current_buf()
  local candidates = vim.lsp.get_clients({ name = "jdtls", bufnr = bufnr })
  local client = candidates and candidates[1] or nil
  return client and client.config and client.config.root_dir or nil
end

local function infer_project_name_from_root(root_dir)
  if utils.is_empty_str(root_dir) or not utils.is_dir(root_dir) then
    return nil
  end

  local eclipse_project = vim.fs.joinpath(root_dir, ".project")
  if utils.exists(eclipse_project) then
    local project_content = utils.read_file(eclipse_project)
    local project_name = get_tag_value(project_content, "name")
    if not utils.is_empty_str(project_name) then
      return project_name
    end
  end

  local pom_file = vim.fs.joinpath(root_dir, "pom.xml")
  if utils.exists(pom_file) then
    local pom_content = utils.read_file(pom_file)
    if pom_content then
      pom_content = pom_content:gsub("<parent>.-</parent>", "")
      local artifact_id = get_tag_value(pom_content, "artifactId")
      if not utils.is_empty_str(artifact_id) then
        return artifact_id
      end
    end
  end

  local root_name = trim(vim.fn.fnamemodify(root_dir, ":t"))
  if not utils.is_empty_str(root_name) then
    return root_name
  end

  return nil
end

local function find_nearest_file(start_dir, filename, stop_dir)
  local dir = start_dir
  stop_dir = utils.normalize_path(stop_dir)

  while not utils.is_empty_str(dir) and utils.is_dir(dir) do
    local candidate = vim.fs.joinpath(dir, filename)
    if utils.exists(candidate) then
      return candidate
    end

    local normalized_dir = utils.normalize_path(dir)
    if not utils.is_empty_str(stop_dir) and normalized_dir == stop_dir then
      break
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

local function infer_project_name_from_path(file_path, root_dir)
  if utils.is_empty_str(file_path) or utils.is_uri(file_path) then
    return nil
  end

  local current_dir = vim.fs.dirname(file_path)
  if utils.is_empty_str(current_dir) or not utils.is_dir(current_dir) then
    return nil
  end

  local nearest_project = find_nearest_file(current_dir, ".project", root_dir)
  if nearest_project then
    local project_content = utils.read_file(nearest_project)
    local project_name = get_tag_value(project_content, "name")
    if not utils.is_empty_str(project_name) then
      return project_name
    end
  end

  local nearest_pom = find_nearest_file(current_dir, "pom.xml", root_dir)
  if nearest_pom then
    local pom_content = utils.read_file(nearest_pom)
    if pom_content then
      pom_content = pom_content:gsub("<parent>.-</parent>", "")
      local artifact_id = get_tag_value(pom_content, "artifactId")
      if not utils.is_empty_str(artifact_id) then
        return artifact_id
      end
    end
  end

  return nil
end

local function infer_project_name_from_buffer(root_dir)
  local bufname = vim.api.nvim_buf_get_name(0)
  return infer_project_name_from_path(bufname, root_dir)
end

local function infer_project_name()
  local root_dir = get_jdtls_root_dir()
  local project_name = infer_project_name_from_buffer(root_dir)
  if not utils.is_empty_str(project_name) then
    return project_name, root_dir
  end
  return infer_project_name_from_root(root_dir), root_dir
end

local function is_java_remote_attach_session(session)
  local config = session and session.config or {}
  return config.type == "java" and config.request == "attach"
end

local function setup_remote_attach()
  local dap = require "dap"

  if not dap.listeners.after.attach[REMOTE_ATTACH_LISTENER_KEY] then
    dap.listeners.after.attach[REMOTE_ATTACH_LISTENER_KEY] = function(session, err)
      if not is_java_remote_attach_session(session) or not err then
        return
      end
      vim.notify("Java remote attach failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  if not dap.listeners.after.event_initialized[REMOTE_ATTACH_LISTENER_KEY] then
    dap.listeners.after.event_initialized[REMOTE_ATTACH_LISTENER_KEY] = function(session)
      if not is_java_remote_attach_session(session) then
        return
      end

      local config = session.config or {}
      local host = config.hostName or "127.0.0.1"
      vim.notify(string.format("Java remote attach succeeded: %s:%s", host, tostring(config.port or "")), vim.log.levels.INFO)
    end
  end

  if not dap.listeners.after.event_stopped[REMOTE_ATTACH_LISTENER_KEY] then
    dap.listeners.after.event_stopped[REMOTE_ATTACH_LISTENER_KEY] = function(session)
      if not is_java_remote_attach_session(session) then
        return
      end

      local config = session.config or {}
      local current_frame = session.current_frame or {}
      local source = current_frame.source or {}
      local frame_path = source.path
      local project_name = infer_project_name_from_path(frame_path, config.cwd)
      if utils.is_empty_str(project_name) then
        return
      end

      if config.projectName ~= project_name then
        config.projectName = project_name
      end
    end
  end

  if remote_attach_setup then
    return
  end

  local java_adapter = dap.adapters.java
  if type(java_adapter) == "function" then
    dap.adapters.java = function(callback, config, parent)
      return java_adapter(function(adapter)
        adapter.options = vim.tbl_extend("force", adapter.options or {}, {
          initialize_timeout_sec = REMOTE_ATTACH_TIMEOUT_MS / 1000,
        })
        if config and config.request == "attach" then
          adapter.enrich_config = function(config_, on_config)
            on_config(config_)
          end
        end
        callback(adapter)
      end, config, parent)
    end
  elseif type(java_adapter) == "table" then
    java_adapter.options = vim.tbl_extend("force", java_adapter.options or {}, {
      initialize_timeout_sec = REMOTE_ATTACH_TIMEOUT_MS / 1000,
    })
  end

  remote_attach_setup = true
end

-- 这个函数提供调试功能
local function debug()
  vim.ui.input({ prompt = "MainClass: " }, function(main_class)
    require("dap").run({
      type = "java",
      request = "launch",
      name = "Launch Main Class",
      mainClass = main_class,
    })
  end)
end

-- 这个函数提供远程调试功能
local function do_remote_debug(host, port)
  local numeric_port = tonumber(port)
  if host and numeric_port then
    local project_name, root_dir = infer_project_name()
    if utils.is_empty_str(root_dir) then
      vim.notify("Java remote attach failed: current buffer is not attached to jdtls", vim.log.levels.ERROR)
      return
    end
    if utils.is_empty_str(project_name) then
      vim.notify("Java remote attach failed: cannot infer projectName from jdtls root", vim.log.levels.ERROR)
      return
    end

    require("dap").run({
      type = "java",
      request = "attach",
      name = "Debug (Attach) - Remote",
      hostName = host,
      port = numeric_port,
      timeout = REMOTE_ATTACH_TIMEOUT_MS,
      projectName = project_name,
      cwd = root_dir,
    })
  else
    vim.notify("Java remote attach failed: invalid port", vim.log.levels.ERROR)
  end
end

-- 通过输入参数提供远程调试能力
local function remote_debug()
  vim.ui.input({ prompt = "Host [127.0.0.1]: " }, function(host)
    if not host or #host == 0 then
      host = "127.0.0.1"
    end
    vim.ui.input({ prompt = "Port [10000]: " }, function(port)
      if not port or #port == 0 then
        port = "10000"
      end
      do_remote_debug(host, port)
    end)
  end)
end

-- 复制引用
local function copy_reference()
  local bufnr = vim.api.nvim_get_current_buf()
  local candidates = vim.lsp.get_clients({ name = "jdtls", bufnr = bufnr })
  if not candidates or #candidates == 0 then
    print("lsp client not found")
    return
  end
  local client = candidates[1]
  client.request("textDocument/hover", vim.lsp.util.make_position_params(0, client.offset_encoding or 'utf-16'), function(_, res, _, _)
    if res and res.contents then
      local sign = #res.contents > 1 and res.contents[1].value or res.contents.value
      vim.fn.setreg('+', sign)
      vim.fn.setreg('"', sign)
    else
      print("reference not found")
    end
  end)
end

local function jump_to_location(uri)
  if not uri then
    return
  end

  if not utils.is_uri(uri) then
    uri = vim.uri_from_fname(uri)
  end

  local pos = {
    character = 0,
    line = 0
  }

  vim.lsp.util.jump_to_location({
    uri = uri,
    range = {
      start = pos,
      ['end'] = pos,
    },
  }, "utf-16")
end

return {
  setup_remote_attach = setup_remote_attach,
  debug            = debug,
  remote_debug     = remote_debug,
  copy_reference   = copy_reference,
  jump_to_location = jump_to_location,
}
