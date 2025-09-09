-- 诊断信息
local diagnostics = {
  "diagnostics",
  sources = { "nvim_diagnostic" },
  sections = { "error", "warn" },
  symbols = { error = " ", warn = " ", info = " ", hint = "" },
  colored = false,
  update_in_insert = false,
  always_visible = false,
}

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        icons_enabled = true,
        -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          "packer",
          "NvimTree",
          "toggleterm",
          "TelescopePrompt",
          "qf",
          "aerial",
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        }
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "filename", "branch", diagnostics },
        lualine_c = { "require('fengwk.custom.lualine-bars').symbol_bar()", "require('dap').status()", "require('fengwk.custom.lualine-bars').lsp_progress()" },
        lualine_x = { "encoding" },
        lualine_y = { "progress" },
        lualine_z = { "location" }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {},
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}
