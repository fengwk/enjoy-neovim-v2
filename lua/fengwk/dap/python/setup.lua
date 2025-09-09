-- https://github.com/mfussenegger/nvim-dap-python
local function setup(_)
  local dap_python = require "dap-python"
  local stdpath_data = vim.fn.stdpath("data")
  local debugpy_home = stdpath_data .. "/mason/packages/debugpy"
  local debugpy_python = debugpy_home .. "/venv/bin/python"
  dap_python.setup(debugpy_python)
end

return setup
