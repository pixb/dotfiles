-- 安装 Lazy.nvim

-- 1. 定义 Lazy.nvim 的安装路径
--    vim.fn.stdpath('data') 获取 Neovim 的数据目录路径
--    通常为: ~/.local/share/nvim
--    然后拼接上 '/lazy/lazy.nvim' 作为最终路径
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- 2. 检查 Lazy.nvim 是否已安装
--    vim.loop.fs_stat() 检查文件/目录是否存在
--    如果不存在，则执行安装操作
if not vim.loop.fs_stat(lazypath) then
	-- 3. 使用 Git 克隆 Lazy.nvim 仓库
	vim.fn.system({
		"git", -- Git 命令
		"clone", -- 克隆操作
		"--filter=blob:none", -- 仅克隆必要的文件，减小克隆大小
		"https://github.com/folke/lazy.nvim.git", -- 仓库地址
		"--branch=stable", -- 使用稳定版本分支
		lazypath, -- 克隆到指定路径
	})
end

-- 4. 将 Lazy.nvim 添加到 Neovim 的运行时路径
--    vim.opt.rtp 是 Neovim 的运行时路径列表
--    prepend() 方法将 Lazy.nvim 的路径添加到列表开头
--    这样 Neovim 就能找到并加载 Lazy.nvim
vim.opt.rtp:prepend(lazypath)

-- 5.分组加载插件
require("lazy").setup({
	-- Init plugins
	{
		import = "pixvim.plugins",
	},
	-- 编辑插件
	{
		import = "pixvim.plugins.editor",
	},
	-- UI 插件
	{
		import = "pixvim.plugins.ui",
		-- gruvbox 主题: lua/plugins/ui/gruvbox.lua
		-- 图标插件: lua/plgins/ui/nvim-web-devicons.lua
		-- Nvim-tree 文件浏览插件: lua/plugins/ui/nvim-tree.lua
	},
	-- lsp 插件
	{
		import = "pixvim.plugins.lsp",
	},
	-- coding
	{
		import = "pixvim.plugins.coding",
	},
	-- util
	{
		import = "pixvim.plugins.util",
	},
	-- lang
	{
		import = "pixvim.plugins.lang",
	},
})
