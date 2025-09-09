local function setup(dap)
  local stdpath_data = vim.fn.stdpath("data")
  local server_file = stdpath_data .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      -- 💀 Make sure to update this path to point to your installation
      args = { server_file, "${port}" },
    }
  }

  dap.configurations.javascript = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
  }
end

return setup
