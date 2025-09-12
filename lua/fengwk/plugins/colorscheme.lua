-- colorscheme 配置
return {
  {
    -- https://github.com/catppuccin/nvim
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require "catppuccin".setup {
        transparent_background = false,
        term_colors = true,
        dim_inactive = {
          enabled = false,
          shade = require "fengwk.globals".theme.bg,
          percentage = 0.15,
        },
        -- https://github.com/catppuccin/nvim#integrations
        integrations = {
          lsp_saga = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
              ok = { "italic" },
            },
            underlines = {
              errors = { "undercurl" },
              hints = { "undercurl" },
              warnings = { "undercurl" },
              information = { "undercurl" },
              ok = { "undercurl" },
            },
            inlay_hints = {
              background = true,
            },
            diffview = true,
          },
          indent_blankline = {
            enabled = true,
            scope_color = "",
            colored_indent_levels = true,
          },
        },
      }

      vim.cmd.colorscheme "catppuccin"
    end,
  },
}
