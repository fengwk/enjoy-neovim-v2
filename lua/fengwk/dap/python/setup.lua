-- https://github.com/mfussenegger/nvim-dap-python
-- local function setup(_)
--   local dap_python = require "dap-python"
--   local stdpath_data = vim.fn.stdpath("data")
--   local debugpy_home = stdpath_data .. "/mason/packages/debugpy"
--   local debugpy_python = debugpy_home .. "/venv/bin/python"
--   dap_python.setup(debugpy_python)
-- end
--
-- return setup

-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#python
local function setup(dap)
  local stdpath_data = vim.fn.stdpath("data")
  local debugpy_home = vim.fs.joinpath(stdpath_data, "mason", "packages", "debugpy")
  local debugpy_python = vim.fs.joinpath(debugpy_home, "venv", "bin", "python")

  dap.adapters.python = function(cb, config)
    if config.request == 'attach' then
      ---@diagnostic disable-next-line: undefined-field
      local port = (config.connect or config).port
      ---@diagnostic disable-next-line: undefined-field
      local host = (config.connect or config).host or '127.0.0.1'
      cb({
        type = 'server',
        port = assert(port, '`connect.port` is required for a python `attach` configuration'),
        host = host,
        options = {
          source_filetype = 'python',
        },
      })
    else
      cb({
        type = 'executable',
        command = debugpy_python,
        args = { '-m', 'debugpy.adapter' },
        options = {
          source_filetype = 'python',
        },
      })
    end
  end

  dap.configurations.python = {
    {
      -- The first three options are required by nvim-dap
      type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
      request = 'launch',
      name = "Launch file",

      -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

      program = "${file}", -- This configuration will launch the current file if used.
      pythonPath = function()
        -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
        -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
        -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
        local cwd = vim.fn.getcwd()
        if vim.fn.executable(vim.fs.joinpath(cwd, "venv", "bin", "python")) == 1 then
          return vim.fs.joinpath(vim.fs.joinpath(cwd, "venv", "bin", "python"))
        elseif vim.fn.executable(vim.fs.joinpath(cwd, ".venv", "bin", "python")) == 1 then
          return vim.fs.joinpath(cwd, ".venv", "bin", "python")
        elseif vim.fn.executable("python3") then
          return "python3"
        else
          return "python"
        end
      end,
    },
  }
end

return setup
