-- 配置
-- 设置 leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.autoformat = true
vim.g.markdown_lint = false
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

-- Snacks 动画
-- `vim.g.snacks_animate` 是一个全局选项，用于控制是否启用 Neovim 的动画效果
-- 设置为 `true` 时，启用各种 UI 动画，如：
-- 光标移动动画
-- 窗口切换动画
-- 状态栏更新动画
-- 滚动动画
-- 这个选项需要配合 `snacks.nvim` 插件使用
-- 动画效果可以提高视觉体验，但可能会影响性能
vim.g.snacks_animate = true

local opt = vim.opt

-- 基本配置
opt.number = true -- 显示行号
opt.relativenumber = true -- 显示相对行号
opt.cursorline = true -- 显示光标所在行的高亮
-- 显示光标所在列的高亮
opt.cursorcolumn = true
opt.signcolumn = "yes" -- 显示侧边栏符号

-- 缩进设置
opt.tabstop = 2 -- 制表符宽度为4
opt.shiftround = true
opt.shiftwidth = 2 -- 自动缩进宽度为4
opt.expandtab = true -- 将制表符转换为空格
opt.smartindent = true -- 智能缩进

-- 搜索设置
opt.ignorecase = true -- 搜索时忽略大小写
opt.smartcase = true -- 智能大小写搜索
opt.hlsearch = true -- 搜索时高亮匹配项
opt.incsearch = true -- 输入搜索模式时实时高亮

-- 文件处理
opt.autoread = true -- 自动读取外部修改的文件

-- 剪贴板
opt.clipboard = "unnamedplus"
-- 如果是在 SSH 环境下，利用 OSC 52 协议同步剪贴板
if vim.env.SSH_CONNECTION then
	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = require("vim.ui.clipboard.osc52").copy("+"),
			["*"] = require("vim.ui.clipboard.osc52").copy("*"),
		},
		paste = {
			["+"] = require("vim.ui.clipboard.osc52").paste("+"),
			["*"] = require("vim.ui.clipboard.osc52").paste("*"),
		},
	}
end

-- 补全菜单设置
-- menu: 弹出菜单
-- menuone: 一个选项也弹出菜单
-- 不自动选择候选词中的第一个候选词
opt.completeopt = "menu,menuone,noselect"

-- Hide * markup for bold and italic, but not markers with substitutions
-- 可隐藏标记的显示方式: 2精简显示
opt.conceallevel = 0

-- Confirm to save changes before exiting modified buffer
-- 开启退出前确认
opt.confirm = true

-- 界面非文字边框
opt.fillchars = {
	foldopen = "",
	foldclose = "",
	fold = " ", -- 隐藏折叠线条
	foldsep = " ",
	diff = "╱",
	eob = " ", -- 隐藏文字末尾的波浪线

	horiz = "━",
	horizup = "┻",
	horizdown = "┳",
	vert = "┃",
	vertleft = "┨",
	vertright = "┣",
	verthoriz = "╋",
}

-- 默认折叠级别
vim.opt.foldlevel = 99
-- 根据Tab/空格来进行缩进深度折叠
opt.foldmethod = "indent"
-- 代码折叠后显示的那一行文字
opt.foldtext = ""

-- 让 gq 使用 LSP 格式化
-- opt.formatexpr = "v:lua.PixVim.format.formatexpr()"

-- 编辑器在自动换行、注释处理和列表排版
-- j: 智能连接：删除换行符（按 `J`）连接两行注释时，自动删除多余的注释符
-- c: 注释换行：在输入注释时达到 `textwidth` 自动换行，并自动补全注释符。
-- r: 回车延续注释：在插入模式下按回车，自动在下一行开头插入当前的注释符。
-- o: `o` 延续注释：在 Normal 模式按 `o` 或 `O` 开启新行时，自动插入注释符。
-- q: `gq` 格式化注释：允许使用 `gq` 命令格式化注释块。
-- l: 长行保护：在插入模式下，如果一行已经很长了，不要自动折行。
-- n: 识别列表：格式化时能识别编号列表（如 `1.`），并保持缩进对齐。
-- t: 自动换行：根据 `textwidth` 自动折行代码（通常不建议代码开启，文档建议开启）。
opt.formatoptions = "jcroqlnt"

-- 设置搜索命令为 ripgrep
opt.grepprg = "rg --vimgrep"
-- 设置解析格式以匹配 rg 的输出
opt.grepformat = "%f:%l:%c:%m"

-- preview incremental substitute
--  增量命令，输入命令时行内实时预览
opt.inccommand = "nosplit"

-- 是 Neovim 中一个专门用于优化 **跳转列表（Jumplist）** 行为的选项。
-- 它决定了当你使用 `Ctrl-O`（跳回）或 `Ctrl-I`（跳前）时，编辑器的光标移动和 UI 表现如何。
-- view: 恢复视图 跳转时尝试恢复当时的屏幕滚动位置（`winview`），而不仅仅是移动光标到对应行。
opt.jumpoptions = "view"

-- global statusline
-- 状态栏的显示行为
-- 3: 全局状态栏: Neovim 特有。无论开了多少个分屏，整个编辑器最底部只有一个共享的状态栏。
opt.laststatus = 3

-- Wrap lines at convenient points
-- 当一行文本太长需要折行显示时，不要在单词中间强行截断。
opt.linebreak = true

-- Show some invisible characters (tabs...
-- Neovim 中用于**显示不可见字符**（如空格、Tab、换行符等）的开关
opt.list = true

-- Enable mouse mode
-- a: 所有模式支持鼠标
opt.mouse = "a"

-- Maximum number of entries in a popup
-- 补全的弹框最多显示行数
opt.pumheight = 10

-- 开启标尺显示
-- 在屏幕右下角显示光标当前的**行号和列号**。
opt.ruler = true

-- 在光标上下方至少保留的行数
-- Lines of context
opt.scrolloff = 4

-- `vim.opt.sessionoptions` 是 Neovim 中用于控制**会话（Session）保存内容**的开关集合。
-- 当你执行 `:mksession` 保存当前工作状态以便下次恢复时，这个选项决定了哪些东西会被写进会话文件。
-- | 标志位 | 保存内容 | 为什么需要它？ |
-- | --- | --- | --- |
-- | **`blank`** | 空窗口 | 是否保留那些没有打开文件的空分割窗口。 |
-- | **`buffers`** | 缓冲区列表 | 恢复后，所有之前打开过的文件（包括隐藏的）都会回到缓冲区。 |
-- | **`curdir`** | 当前工作目录 | 确保恢复会话后，你的 `:pwd` 路径与离开时一致。 |
-- | **`folds`** | **折叠状态** | 极其重要！保存哪些代码块是展开的，哪些是折叠的。 |
-- | **`help`** | 帮助窗口 | 是否保留打开的 Vim 帮助文档窗口。 |
-- | **`tabpages`** | 标签页 | 保存所有打开的 Tab 页。 |
-- | **`winsize`** | 窗口尺寸 | 恢复每个分屏的精确高度和宽度。 |
-- | **`terminal`** | 终端窗口 | (Neovim 特有) 尝试恢复内置终端（通常只恢复窗口，不恢复进程）。 |
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- 精简 Neovim 消息提示的选项
-- Neovim `shortmess` 选项各标志含义说明：
-- a  - 全部缩写：相当于 filnxtToOF 的组合，将绝大多数消息缩写显示，
--      例如用 [L] 代替 [line]。
-- c  - 补全静默：最常用！禁用补全时的匹配提示（如 "match 1 of 2"），
--      避免命令行闪烁干扰。
-- f  - 文件信息缩写：将 "(filename) [line 1 of 10]" 简化为 "(filename) [1/10]"。
-- F  - 不提示文件信息：执行 :w 写入文件时，不显示具体文件路径等信息。
-- I  - 跳过启动页：启动 Neovim 时不显示默认欢迎信息（含版本号和捐赠提示）。
-- W  - 不提示写入成功：保存文件后不显示 "Written" 消息。
opt.shortmess:append({ W = true, I = true, c = true, C = true })

-- Dont show mode since we have a statusline
opt.showmode = false

-- Columns of context
-- 水平滚动保持空白文本数
opt.sidescrolloff = 8

-- 启用平滑滚动 nvim 0.10+
opt.smoothscroll = true

opt.spelllang = { "en" }

-- Put new windows below current
opt.splitbelow = true
opt.splitkeep = "screen"
-- Put new windows right of current
opt.splitright = true

-- 状态栏内容与外观
opt.statuscolumn = [[%!v:lua.PixVim.statuscolumn()]]
-- opt.statuscolumn = "%s%=%{%v:relnum ? v:relnum : v:lnum%}"
opt.termguicolors = true -- True color support
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
