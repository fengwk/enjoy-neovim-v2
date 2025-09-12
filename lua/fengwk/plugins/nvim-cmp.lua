local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local conflict_cn_tab = {
  "AvanteInput", -- Avante 输入与 <C-n> 冲突
}

local function conflict_cn()
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  return vim.tbl_contains(conflict_cn_tab, ft)
end

return {
  "hrsh7th/nvim-cmp",
  event = "VeryLazy",
  config = function()
    local cmp = require "cmp"

    -- 编辑补全
    cmp.setup {
      -- 补全列表出现时不会自动选择, 可以避免一些源 (如 golsp) 自动选择第一个选项导致操作体验不一致
      preselect = cmp.PreselectMode.None,
      -- snippets
      snippet = {
        expand = function(args)
          -- 安装vsnip
          vim.fn["vsnip#anonymous"](args.body)
        end,
      },
      completion = {
        -- 指定自动补全的时机
        autocomplete = {
          'InsertEnter',
          'TextChanged',
        },
      },
      -- 快捷键映射
      mapping = {
        -- 向上滚动补全项文档
        ["<C-u>"] = cmp.mapping.scroll_docs(-5),
        -- 向下滚动补全项文档
        ["<C-d>"] = cmp.mapping.scroll_docs(5),
        -- 关闭补全项窗口
        ["<C-c>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            (cmp.mapping.abort())()
          else
            fallback()
          end
        end, { "i", "s" }),
        -- 确认补全项, select 为 true 表示没有选项时默认选择第一个, false 则不做选择进行换行
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        -- 下一个补全项
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            -- cmp 补全可见, 到下一项
            cmp.select_next_item()
          elseif vim.fn["vsnip#available"](1) == 1 then
            -- vsnip 可见, 到下一个插入位置
            feedkey("<Plug>(vsnip-expand-or-jump)", "")
          else
            -- 使用 Tab 原功能
            fallback()
          end
        end, { "i", "s" }),
        -- 上一个补全项
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif vim.fn["vsnip#jumpable"](-1) == 1 then
            feedkey("<Plug>(vsnip-jump-prev)", "")
          else
            fallback()
          end
        end, { "i", "s" }),
        -- 将 neovim 内置补全快捷键替换为 cmp 补全
        ["<C-n>"] = cmp.mapping(function(fallback)
          if not cmp.visible() and not conflict_cn() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
      },
      -- 补全来源
      sources = {
        {
          name = "nvim_lsp",
          entry_filter = function(entry, _)
            -- 过滤 lsp 返回的 Text
            return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
          end,
        },
        { name = "vsnip" },
        { name = "path" },
        {
          name = "buffer",
          option = {
            -- 可见缓冲区作为 buffer 来源
            get_bufnrs = function()
              local bufs = {}
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                bufs[vim.api.nvim_win_get_buf(win)] = true
              end
              return vim.tbl_keys(bufs)
            end
          },
          indexing_interval = 200,
          indexing_batch_size = 1000,
          max_indexed_line_length = 1024 * 4,
        },
      },

      enabled = function()
        return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
            or require("cmp_dap").is_dap_buffer()
      end,

      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
    }

    -- dap 补全
    require("cmp").setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
      sources = {
        { name = "dap" },
      },
    })

    -- 命令补全
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "cmdline" },
        { name = "path" },
      },
    })
  end,
  dependencies = {
    "hrsh7th/cmp-buffer",   -- 缓冲区
    "hrsh7th/cmp-path",     -- 路径
    "hrsh7th/cmp-cmdline",  -- 命令
    "hrsh7th/cmp-nvim-lsp", -- lsp
    "rcarriga/cmp-dap",     -- nvim-dap REPL and nvim-dap-ui buffers
    "hrsh7th/cmp-vsnip",    -- 将 vim-vsnip 桥接到 nvim-cmp 上
    {
      -- https://github.com/hrsh7th/vim-vsnip
      "hrsh7th/vim-vsnip", -- vscode 规范的 snippets 补全
      config = function()
        -- 指定个人snippets文件夹位置，可以参考friendly-snippets
        -- https://github.com/rafamadriz/friendly-snippets/tree/main/snippets
        vim.g.vsnip_snippet_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "my-snippets")

        -- snippets补全后会进入select模式，编辑会进入insert模式，指定在这两个模式下的跳跃
        vim.cmd([[
        " Jump forward or backward
        imap <expr> <C-j> vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<C-j>'
        smap <expr> <C-j> vsnip#jumpable(1)  ? '<Plug>(vsnip-jump-next)' : '<C-j>'
        imap <expr> <C-k> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<C-k>'
        smap <expr> <C-k> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<C-k>'
        ]])
      end
    },
  },
}
