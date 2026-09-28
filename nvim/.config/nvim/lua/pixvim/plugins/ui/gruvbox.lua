return {
	-- add gruvbox
	{
		"ellisonleao/gruvbox.nvim",
		-- 不懒加载
		lazy = false,
		-- 优先级1000,确保在其他插件之前加载
		priority = 1000,
		-- 插件配置函数
		config = function()
            require("gruvbox").setup({
              terminal_colors = true,
              undercurl = true,
              underline = true,
              bold = true,
              italic = {
                strings = true,
                emphasis = true,
                comments = true,
                operators = false,
                folds = true,
              },
              strikethrough = true,
              invert_selection = false,
              invert_signs = false,
              invert_tabline = false,
              invert_intend_guides = false,
              inverse = true,
              contrast = "",
              palette_overrides = {},
              overrides = {},
              dim_inactive = false,
              transparent_mode = false,
            })
			-- 应用 gruvbox 主题
			vim.cmd("colorscheme gruvbox")
		end,
	},
}
