local globals = require "fengwk.globals"

return {
  {
    -- https://github.com/3rd/diagram.nvim
    "3rd/diagram.nvim",
    event = "VeryLazy",
    config = function()
      local diagram = require "diagram"
      diagram.setup {
        events = {
          render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
          clear_buffer = { "WinClosed" },
          -- clear_buffer = { "InsertEnter" },
        },
        renderer_options = {
          mermaid = {
            background = "transparent",
            theme = globals.theme.bg,
            scale = 2,
          },
          plantuml = {
            cli_args = { "-Djava.awt.headless=true" },
          },
        },
      }
    end,
    dependencies = {
      {
        -- https://github.com/3rd/image.nvim
        -- 推荐使用 kitty 终端, 依赖 imagemagick
        -- 如果使用 tmux 需要配置
        -- set -gq allow-passthrough on
        -- set -g visual-activity off
        -- "3rd/image.nvim",
        -- 这个分支调整了触发时机让插件更符合当前配置
        -- 取消 TextChangedI, BufWinEnter -> BufEnter
        "fengwk/image.nvim",
        branch = "dev",
        event = "VeryLazy",
        config = function()
          local image = require "image"
          image.setup {
            backend = "kitty",        -- or "ueberzug" or "sixel"
            processor = "magick_cli", -- or "magick_rock"
            integrations = {
              markdown = {
                enabled = true,
                clear_in_insert_mode = false,                -- 插入模式清除防止图片错乱
                download_remote_images = true,
                only_render_image_at_cursor = false,         -- 开启则仅在光标在图片行才展示
                only_render_image_at_cursor_mode = "inline", -- 如果开启 only_render_image_at_cursor 的展示行为
                filetypes = globals.markdown_filetypes,
              },
              neorg = { enabled = false },
              typst = { enabled = false },
              html = { enabled = false },
              css = { enabled = false },
            },
            window_overlap_clear_enabled = true, -- 窗口覆盖时清理
            window_overlap_clear_ft_ignore = {
              "cmp_menu",
              "cmp_docs",
              "" -- qf preview 窗口
            },
            scale_factor = 1.0,
            max_height_window_percentage = 50,
            -- 如果开启则只在编辑器聚焦的时候渲染
            editor_only_render_when_focused = false,
            -- 这个配置很重要, 解决了 tmux 窗口切换图片残留的问题
            -- https://github.com/3rd/image.nvim/issues/233
            tmux_show_only_in_active_window = true,
          }

          vim.api.nvim_create_user_command("ImageEnable", image.enable, {})
          vim.api.nvim_create_user_command("ImageDisable", image.disable, {})

          -- 仅对 kitty 默认开启
          local enable = os.getenv("TERM") == "xterm-kitty"
          if not enable then
            image.disable()
          end
        end,
      },
    },
  },
  {
    -- https://github.com/hakonharnes/img-clip.nvim
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        relative_to_current_file = true,
        show_dir_path_in_prompt = true,
        embed_image_as_base64 = false,
        drag_and_drop = {
          -- 关闭该功能，因为拖拽复制功能会包装 vim.paste 导致每次 URL paste 都需要下载内容，影响非图片 URL paste 性能
          enabled = false,
          -- insert_mode = true,
        },
        use_absolute_path = function()
          return false
        end
      },
    },
    keys = {
      -- suggested keymap
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
}
