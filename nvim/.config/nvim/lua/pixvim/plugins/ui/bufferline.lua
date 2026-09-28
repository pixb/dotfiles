return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    -- 快捷键懒加载，按键触发插件加载，desc字段，方便 which-key.nvim 等插件显示提示
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    },
    -- 配置选项
    opts = {
      options = {
        -- stylua: ignore
        close_command = function(n) Snacks.bufdelete(n) end,
        -- stylua: ignore
        right_mouse_command = function(n) Snacks.bufdelete(n) end,
        -- 诊断指示器
        -- 可选值: "nvim_lsp", "coc", "none"
        -- "nvim_lsp" 使用 Neovim 内置的 LSP 客户端
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        -- 自定义诊断指示器函数
        -- 参数说明:
        --   count: 当前级别的诊断数量
        --   level: 诊断级别 ("error", "warning", "info", "hint")
        --   diagnostics_dict: 包含所有诊断信息的字典
        --   context: 额外的上下文信息
        diagnostics_indicator = function(_, _, diag)
          -- 获取图标配置
          local icons = PixVim.config.icons.diagnostics
          -- 根据错误信息来拼接错误信息与图标的拼接
          local ret = (diag.error and icons.Error .. diag.error .. " " or "")
            .. (diag.warning and icons.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        -- 与 nvim-tree 集成，为 nvim-tree 来预留控件
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
          {
            filetype = "snacks_layout_box",
          },
        },
        ---@param opts bufferline.IconFetcherOpts
        get_element_icon = function(opts)
          return PixVim.config.icons.ft[opts.filetype]
        end,
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}
