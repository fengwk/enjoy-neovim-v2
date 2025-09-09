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
          shade = "dark",
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
          },
        },
      }

      vim.cmd.colorscheme "catppuccin"
    end,
  },
}
