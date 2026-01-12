local globals = require "fengwk.globals"
local utils = require "fengwk.utils"
local workspaces = require "fengwk.custom.workspaces"

local function is_arm()
  local sys_arch = utils.system "uname -m" or ""
  return string.find(sys_arch, "armv71") ~= nil or string.find(sys_arch, "aarch64") ~= nil
end

-- 定义所有要安装的 lsp
local lsp_pkgs = {
  "bashls",                                                                       -- bash
  -- arm 架构不支持 calngd
  utils.has_cmd("gcc") and not is_arm() and "clangd" or nil,                      -- c cpp
  utils.has_cmd("npm") and "cssls" or nil,                                        -- css less scss
  utils.has_cmd("go") and "gopls" or nil,                                         -- go
  -- (utils.has_cmd("java") or os.getenv("JAVA_HOME") ~= nil) and "groovyls" or nil, -- groovy
  "lua_ls" or nil,                                                                -- lua
  "pylsp" or nil,                                                                 -- python
  utils.has_cmd("npm") and "ts_ls" or nil,                                        -- js ts
  utils.has_cmd("npm") and "eslint" or nil,                                       -- eslint
  "jdtls" or nil,                                                                 -- java
}

-- 定义所有要安装的 dap
local dap_pkgs = {
  "cppdbg",
  "delve",
  "js",
  "python",
  "javadbg",
  "javatest",
}

local function get_range()
  return {
    start = vim.api.nvim_buf_get_mark(0, '<'),
    ["end"] = vim.api.nvim_buf_get_mark(0, '>'),
  }
end

local function bind_lsp_keymaps(bufnr)
  local keymap = vim.keymap.set

  -- 信息
  keymap("n", "K", vim.lsp.buf.hover,
    { noremap = true, silent = true, buffer = bufnr, desc = "Lsp Hover" })

  -- 操作
  keymap("n", "<leader>rn", vim.lsp.buf.rename,
    { noremap = true, silent = true, buffer = bufnr, desc = "Lsp Rename" })
  keymap("n", "<leader>ca", vim.lsp.buf.code_action,
    { noremap = true, silent = true, buffer = bufnr, desc = "Lsp Code Action" })
  keymap("v", "<leader>ca", function()
    local range = get_range();
    vim.api.nvim_input("<Esc>")
    vim.lsp.buf.code_action({ range = range })
  end, { noremap = true, silent = true, buffer = bufnr, desc = "Lsp Range Code Action" })
  keymap("n", "<leader>fm", function() vim.lsp.buf.format({ async = true }) end,
    { noremap = true, silent = true, buffer = bufnr, desc = "Lsp Formatting" })
  keymap("v", "<leader>fm", function()
    local range = get_range();
    vim.api.nvim_input("<Esc>")
    vim.lsp.buf.format({ range = range, async = true })
  end, { noremap = true, silent = true, buffer = bufnr, desc = "Lsp Range Formatting" })

  -- 导航
  keymap("n", "gs", "<Cmd>Telescope lsp_document_symbols<CR>",
    { silent = true, buffer = bufnr, desc = "Lsp Document Symbols" })
  keymap("n", "gw", "<Cmd>Telescope lsp_dynamic_workspace_symbols<CR>",
    { buffer = bufnr, desc = "Lsp Workspace Symbol" })
  keymap("n", "gr", "<Cmd>Telescope lsp_references<CR>",
    { buffer = bufnr, desc = "Lsp References" })
  keymap("n", "g<leader>", "<Cmd>Telescope lsp_implementations<CR>",
    { buffer = bufnr, desc = "Lsp Implementation" })
  keymap("n", "gd", "<Cmd>Telescope lsp_definitions<CR>",
    { buffer = bufnr, desc = "Lsp Definition" })
  keymap("n", "gD", vim.lsp.buf.declaration,
    { silent = true, buffer = bufnr, desc = "Lsp Declaration" })
  keymap("n", "gt", "<Cmd>Telescope lsp_type_definitions<CR>",
    { buffer = bufnr, desc = "Lsp Type Definition" })
  keymap("n", "gW", vim.lsp.buf.workspace_symbol,
    { buffer = bufnr, desc = "Lsp Workspace Symbols" })
end

local function bind_dap_keymaps(bufnr)
  local dap = require "dap"

  -- 断点开关
  vim.keymap.set("n", "<leader>db", function()
    dap.toggle_breakpoint()
  end, { buffer = bufnr, desc = "Dap Breakpoint" })
  -- 条件断点
  vim.keymap.set("n", "<leader>dc", function()
    vim.ui.input({ prompt = "Debug Condition: " }, function(cond)
      if cond then
        dap.toggle_breakpoint(cond)
      end
    end)
  end, { buffer = bufnr, desc = "Dap Breanpoint With Condition" })
  -- 日志断点，允许不暂停但在变量上设置表达式如x = {x}就会在repl上打印输出对应x =的变量值
  vim.keymap.set("n", "<leader>dl", function()
    vim.ui.input({ prompt = "Debug Log: " }, function(log)
      if log then
        dap.toggle_breakpoint(nil, nil, log)
      end
    end)
  end, { buffer = bufnr, desc = "Dap Breanpoint With Log" })
  -- 清理所有断点
  vim.keymap.set("n", "<leader>dC", "<Cmd>lua require('dap').clear_breakpoints()<CR>",
    { buffer = bufnr, silent = true, desc = "Dap Clear Breakpoints" })
  -- 执行最后一次的run
  vim.keymap.set("n", "<leader>dL", "<Cmd>lua require('dap').run_last()<CR>",
    { buffer = bufnr, silent = true, desc = "Dap Run Last" })
  -- REPL开关
  vim.keymap.set("n", "<leader>dr", function()
    local current_win = vim.api.nvim_get_current_win()
    local current_width = vim.api.nvim_win_get_width(current_win)
    local width = math.max(15, math.ceil(current_width / 3))
    dap.repl.toggle({ width = width, wrap = true }, "rightbelow vsplit")
    vim.cmd("wincmd p") -- 聚焦窗口
  end, { buffer = bufnr, silent = true, desc = "Dap REPL" })
  vim.keymap.set("n", "<F5>", "<Cmd>lua require('dap').step_into()<CR>",
    { buffer = bufnr, silent = true, desc = "Dap Step Into" })
  vim.keymap.set("n", "<F6>", "<Cmd>lua require('dap').step_over()<CR>",
    { buffer = bufnr, silent = true, desc = "Dap Step Over" })
  vim.keymap.set("n", "<F7>", "<Cmd>lua require('dap').step_out()<CR>",
    { buffer = bufnr, silent = true, desc = "Dap Setp Out" })
  -- 这个命令同时可以启动debug
  vim.keymap.set("n", "<F8>", "<Cmd>lua require('dap').continue()<CR>",
    { buffer = bufnr, silent = true, desc = "Dap Continue" })
  -- 关闭当前session
  vim.keymap.set("n", "<leader>dt", "<Cmd>lua require('dap').terminate()<CR>",
    { buffer = bufnr, silent = true, desc = "Dap Terminate" })
end

local function bind_lspsaga_keymaps(bufnr)
  -- 当前作用域的上游（从哪些地方进来）
  vim.keymap.set("n", "<leader>gi", "<Cmd>Lspsaga incoming_calls<CR>",
    { silent = true, buffer = bufnr, desc = "Lsp Incoming Calls" })
  -- 当前作用域的下游（去到哪些地方）
  vim.keymap.set("n", "<leader>go", "<Cmd>Lspsaga outgoing_calls<CR>",
    { silent = true, buffer = bufnr, desc = "Lsp Outgoing Calls" })
  -- 打开outline
  vim.keymap.set("n", "<leader>oo", "<Cmd>Lspsaga outline<CR>", { desc = "Outline" })
end

local function get_lsp_conf(server)
  local ok, conf = pcall(require, "fengwk.lsp." .. server .. ".conf")
  if ok and conf then
    return conf
  end
  return {}
end

local function get_lsp_setup(server)
  local ok, setup = pcall(require, "fengwk.lsp." .. server .. ".setup")
  if ok and setup then
    return setup
  end
  return nil
end

local function get_dap_setup(pkg)
  local ok, setup = pcall(require, "fengwk.dap." .. pkg .. ".setup")
  if ok and setup then
    return setup
  end
  return nil
end

local function build_lsp_conf(server, capabilities)
  return vim.tbl_extend("keep", get_lsp_conf(server), {
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      bind_lsp_keymaps(bufnr)
      bind_dap_keymaps(bufnr)
      bind_lspsaga_keymaps(bufnr)

      -- 定位到根目录, 如果是单文件 lsp 则不会重定位
      local root_dir = client.root_dir
      if not utils.is_empty_str(root_dir) and utils.is_dir(root_dir) then
        utils.cd(root_dir)
        -- workspaces.add(root_dir)
      end

      -- 使用 telescope 搜索诊断信息
      vim.keymap.set("n", "<leader>fd", "<Cmd>lua require('telescope.builtin').diagnostics()<CR>",
        { silent = true, desc = "Telescope Diagnostics" })
      -- 诊断跳转
      vim.keymap.set("n", "[d", function()
        vim.diagnostic.jump({ count = -1, float = true })
      end, { silent = true, desc = "Diagnostic Prev" })
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.jump({ count = 1, float = true })
      end, { silent = true, desc = "Diagnostic Next" })
    end,
    handlers = {
      -- 仅在插入模式下响应 lsp 补全, 避免在非插入模式下触发 "complete() can only be used in Insert mode" 错误
      ["textDocument/completion"] = function(err, result, method, params)
        if vim.api.nvim_get_mode().mode == 'i' then
          vim.lsp.handlers["textDocument/completion"](err, result, method, params)
        end
      end,
      ["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
          border = globals.theme.border,
        }
      )
    },
  })
end

local function set_dap_sign()
  local dap_breakpoint = {
    -- 普通断点
    error = {
      text = "",
      texthl = "DapBreakpoint",
      linehl = "DapBreakpoint",
      numhl = "DapBreakpoint",
    },
    -- 条件断点
    condition = {
      text = '󰯲',
      texthl = 'DapBreakpoint',
      linehl = 'DapBreakpoint',
      numhl = 'DapBreakpoint',
    },
    -- 无法debug的断点
    rejected = {
      text = "",
      texthl = "DapBreakpint", -- catppuccin中为灰色
      linehl = "DapBreakpoint",
      numhl = "DapBreakpoint",
    },
    logpoint = {
      text = '󰰍',
      texthl = 'DapLogPoint',
      linehl = 'DapLogPoint',
      numhl = 'DapLogPoint',
    },
    stopped = {
      text = '',
      texthl = 'DapStopped',
      linehl = 'DapStopped',
      numhl = 'DapStopped',
    },
  }

  vim.fn.sign_define('DapBreakpoint', dap_breakpoint.error)
  vim.fn.sign_define('DapBreakpointCondition', dap_breakpoint.condition)
  vim.fn.sign_define('DapBreakpointRejected', dap_breakpoint.rejected)
  vim.fn.sign_define('DapLogPoint', dap_breakpoint.logpoint)
  vim.fn.sign_define('DapStopped', dap_breakpoint.stopped)
end

local function get_closeable_lsp_clients(bufnr)
  local closeable_clients = {}
  if bufnr and bufnr > 0 then
    local clients = vim.lsp.get_clients()
    -- 遍历所有lsp客户端
    for _, c in pairs(clients) do
      -- copilot会在所有缓冲区打开因此不做处理
      if c and c.id and c.name ~= "copilot" then
        -- 遍历指定客户端关联的所有缓冲区
        local lsp_bufs = vim.lsp.get_buffers_by_client_id(c.id)
        if not lsp_bufs or #lsp_bufs == 0
            or (#lsp_bufs == 1 and lsp_bufs[1] == bufnr) then
          table.insert(closeable_clients, c)
        end
      end
    end
  end
  return closeable_clients
end

local function close_client(c)
  if c then
    vim.schedule(function()
      vim.lsp.stop_client(c.id)
      vim.notify("lsp client " .. c.name .. "[" .. c.id .. "]" .. " closed")
      -- 过30秒如果还存在则强制关闭
      vim.defer_fn(function()
        local exists = vim.lsp.get_client_by_id(c.id)
        if exists then
          local lsp_bufs = vim.lsp.get_buffers_by_client_id(c.id)
          if not lsp_bufs or #lsp_bufs == 0 then
            vim.lsp.stop_client(c.id, { force = true })
          end
        end
      end, 30000)
    end)
  end
end

local function register_lsp_destruction()
  -- 设置lsp关闭钩子
  vim.api.nvim_create_augroup("lsp_destruction", { clear = true })
  vim.api.nvim_create_autocmd(
    { "BufDelete" },
    {
      group = "lsp_destruction",
      callback = function(args)
        -- args.buf是当前被销毁的缓冲区
        if args and args.buf and args.buf > 0 then
          local closeableClients = get_closeable_lsp_clients(args.buf)
          for _, c in ipairs(closeableClients) do
            close_client(c);
          end
        end
      end
    }
  )
end

return {
  {
    -- 依赖 git curl unzip tar gzip wget
    "mason-org/mason.nvim",
    config = function()
      local mason = require "mason"
      local mason_lspconfig = require "mason-lspconfig"

      mason.setup {
        log_level = vim.log.levels.INFO,
        ui = {
          border = globals.theme.border,
        },
      }

      -- mason wrap
      local group = vim.api.nvim_create_augroup("user_mason_view", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "mason",
        callback = function()
          vim.wo.wrap = true
        end,
      })

      mason_lspconfig.setup {
        ensure_installed = vim.tbl_filter(function(value) return value end, lsp_pkgs),
        automatic_enable = false, -- 手动 setup lsp
      }

      -- 缓冲区删除时自动关闭空 lsp
      register_lsp_destruction()

      -- 定义 lsp 日志级别
      -- TRACE DEBUG INFO WARN ERROR OFF
      vim.lsp.set_log_level("INFO")

      -- 设置 ui
      require "lspconfig.ui.windows".default_options.border = globals.theme.border
      local source_fn = vim.lsp.util.open_floating_preview
      vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = globals.theme.border -- 指定lsp预览的边框样式
        return source_fn(contents, syntax, opts, ...)
      end


      local capabilities = require "blink.cmp".get_lsp_capabilities()
      local servers = mason_lspconfig.get_installed_servers()
      for _, server in ipairs(servers) do
        local conf = build_lsp_conf(server, capabilities)
        local setup = get_lsp_setup(server)
        if setup then
          setup(conf)
        else
          utils.setup_lsp(server, conf, true)
        end
      end

      vim.keymap.set("n", "<leader>ll", "<Cmd>LspStart<CR>", {})
      vim.keymap.set("n", "<leader>ls", "<Cmd>LspStop<CR>", {})
      vim.keymap.set("n", "<leader>lr", "<Cmd>LspRestart<CR>", {})

      -- https://github.com/jay-babu/mason-nvim-dap.nvim
      local dap = require "dap"
      local mason_nvim_dap = require "mason-nvim-dap"
      local final_dap_pkgs = vim.tbl_filter(function(value) return value end, dap_pkgs)
      mason_nvim_dap.setup {
        -- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
        ensure_installed = vim.tbl_filter(function(value) return value end, final_dap_pkgs),
      }

      for _, pkg in ipairs(final_dap_pkgs) do
        local setup = get_dap_setup(pkg)
        if setup then
          setup(dap)
        end
      end

      dap.defaults.fallback.terminal_win_cmd = "belowright 12new" -- 在下方打开 dap terminal, 12行高度

      -- 关闭terminal时自动删除缓冲区，避免无法在新的session中重新打开terminal
      -- https://github.com/mfussenegger/nvim-dap/issues/603
      local group2 = vim.api.nvim_create_augroup("user_dap_close", { clear = true })
      vim.api.nvim_create_autocmd("BufHidden", {
        group = group2,
        callback = function(arg)
          if arg and arg.file and string.find(arg.file, "[dap-terminal]", 1, true) then
            vim.schedule(function()
              vim.api.nvim_buf_delete(arg.buf, { force = true })
            end)
          end
        end
      })

      if not utils.is_tty() then
        set_dap_sign()
      end
    end,
    dependencies = {
      "neovim/nvim-lspconfig",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",    -- 补全依赖项
      "mfussenegger/nvim-jdtls", -- java
      {
        "nvimdev/lspsaga.nvim",
        config = function()
          local kind = nil
          local ok, catppuccin_lspsaga = pcall(require, "catppuccin.groups.integrations.lsp_saga")
          if ok then
            kind = catppuccin_lspsaga.custom_kind()
          end

          require "lspsaga".setup {
            ui = {
              border = globals.theme.border,
              devicon = true,
              title = true,
              expand = '⊞',
              collapse = '⊟',
              code_action = '💡',
              actionfix = ' ',
              lines = { '└', '├', '│', '─', '┌' },
              kind = kind,
              imp_sign = '󰳛 ',
            },
            symbol_in_winbar = {
              enable = false,
              show_file = false,
              color_mode = true, -- 在lualine中剔除颜色标记
              dely = 10,
            },
            lightbulb = {
              enable = false,
            },
            finder = {
              keys = {
                shuttle = '<Tab>',
                toggle_or_open = 'o',
                vsplit = '<C-v>',
                split = '<C-x>',
                tabe = '<C-t>',
                tabnew = '<C-T>',
                quit = 'q',
                close = '<C-c>',
              },
            },
            definition = {
              keys = {
                edit = '<C-e>',
                vsplit = '<C-v>',
                split = '<C-x>',
                tabe = '<C-t>',
                quit = 'q',
                close = '<C-c>',
              },
            },
            rename = {
              keys = {
                quit = '<C-c>',
                exec = '<CR>',
              },
            },
            outline = {
              win_position = 'right',
              win_width = 45,
              auto_preview = true,
              detail = true,
              auto_close = true,
              close_after_jump = false,
              layout = 'normal',
              max_height = 0.5,
              left_width = 0.3,
              keys = {
                toggle_or_jump = 'o',
                quit = 'q',
                jump = '<Enter>',
              },
            },
            callhierarchy = {
              layout = 'float',
              left_width = 0.2,
              keys = {
                edit = '<Enter>',
                vsplit = '<C-v>',
                split = '<C-x>',
                tabe = '<C-t>',
                close = '<C-c>',
                quit = 'q',
                shuttle = '<Tab>',
                toggle_or_req = 'o',
              },
            },
            beacon = {
              enable = false,
            },
          }

          -- 打开当前 cwd 路径的终端
          vim.keymap.set({ "n" }, "<leader>tt", "<Cmd>Lspsaga term_toggle<CR>", { desc = "Float Terminal" })
          -- 打开当前文件路径的终端
          vim.keymap.set({ "n" }, "<leader>t<CR>", function()
            vim.api.nvim_command("Lspsaga term_toggle " .. os.getenv("SHELL") .. " " .. vim.fn.expand("%:p:h"))
          end, { desc = "Float Terminal On Current Buffer Directory" })
          -- 自动关闭 lsp saga terminal
          vim.keymap.set({ "t" }, "<C-q>", "<Cmd>Lspsaga term_toggle<CR>", { desc = "Float Terminal" })
        end,
        dependencies = {
          "kyazdani42/nvim-web-devicons",
        },
      },

      -- dap | Debug Adapter Protocol
      "mfussenegger/nvim-dap",
      "jay-babu/mason-nvim-dap.nvim",
      "leoluz/nvim-dap-go",
      -- "mfussenegger/nvim-dap-python",
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
          enabled = true,                        -- enable this plugin (the default)
          enabled_commands = true,               -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
          highlight_changed_variables = true,    -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
          highlight_new_as_changed = false,      -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
          show_stop_reason = true,               -- show stop reason when stopped for exceptions
          commented = false,                     -- prefix virtual text with comment string
          only_first_definition = true,          -- only show virtual text at first definition (if there are multiple)
          all_references = false,                -- show virtual text on all all references of the variable (not only definitions)
          filter_references_pattern = '<module', -- filter references (not definitions) pattern when all_references is activated (Lua gmatch pattern, default filters out Python modules)
          -- experimental features:
          virt_text_pos = 'eol',                 -- position of virtual text, see `:h nvim_buf_set_extmark()`
          all_frames = false,                    -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
          virt_lines = false,                    -- show virtual lines instead of virtual text (will flicker!)
          virt_text_win_col = nil                -- position the virtual text at a fixed window column (starting from the first text column) ,
          -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
        },
      },
    },
  }
}
