-- 在你的配置文件中添加
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.diagnostic.enable(false, { bufnr = 0 })
	end,
})
