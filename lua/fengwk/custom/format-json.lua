local format_json = vim.fs.joinpath(vim.fn.stdpath("config"), "lib", "format-json.py")
local compress_json = vim.fs.joinpath(vim.fn.stdpath("config"), "lib", "compress-json.py")

local mode_range_map = {
  v = "'<,'>",
  l = "line(\".\")",
  n = "%",
}

local function build_format_json_cmd(mode)
  local shiftwidth = vim.api.nvim_buf_get_option(0, "shiftwidth") or 4
  return mode_range_map[mode] .. "!python3 " .. format_json .. " -i " .. shiftwidth
end

local function build_compress_json_cmd(mode)
  return mode_range_map[mode] .. "!python3 " .. compress_json
end

local group = vim.api.nvim_create_augroup("user_format_json", { clear = true })
vim.api.nvim_create_autocmd(
  { "FileType" },
  {
    group = group,
    pattern = "json,jsonc",
    callback = function()
      vim.keymap.set("n", "<leader>fm", function() vim.cmd(build_format_json_cmd("n")) end,
        { silent = true, buffer = 0, desc = "Format JSON" })
      vim.keymap.set("x", "<leader>fm", function() vim.cmd(build_format_json_cmd("v")) end,
        { silent = true, buffer = 0, desc = "Format JSON" })
      vim.keymap.set("n", "<leader>fM", function() vim.cmd(build_compress_json_cmd("n")) end,
        { silent = true, buffer = 0, desc = "Compress JSON" })
      vim.keymap.set("x", "<leader>fM", function() vim.cmd(build_compress_json_cmd("v")) end,
        { silent = true, buffer = 0, desc = "Compress JSON" })
    end
  })
