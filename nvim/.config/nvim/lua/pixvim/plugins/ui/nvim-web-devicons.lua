return {
	-- 文件图标插件（可选，但推荐）
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true, -- 懒加载，仅在需要时加载
		config = function()
			require("nvim-web-devicons").setup({
				default = true,
			})
		end,
	},
}
