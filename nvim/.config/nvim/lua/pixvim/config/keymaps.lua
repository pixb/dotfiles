-- 设置快捷键
local M = {}
-- 对 vim.keymap.set 的封装函数，具有以下两个特性：
-- 1. 如果 Lazy.nvim 已为该快捷键注册了延迟加载（lazy key）处理程序，则**不创建**此快捷键映射；
-- 2. 默认启用 `silent = true`（即不显示命令行回显），除非显式设为 false。
function M.safe_keymap_set(mode, lhs, rhs, opts)
	-- 获取 Lazy.nvim 内部的按键处理器，用于检查是否已存在 lazy key handler
	local keys = require("lazy.core.handler").handlers.keys
	---@cast keys LazyKeysHandler  -- 告诉 LSP/静态分析工具 keys 的类型

	-- 将 mode 标准化为字符串列表：
	-- 如果传入的是单个字符串（如 "n"），转为 { "n" }；
	-- 如果传入的是表（如 { "n", "v" }），则保持原样。
	local modes = type(mode) == "string" and { mode } or mode

	-- 过滤掉那些已经被 Lazy.nvim 注册为 lazy key 的模式（mode）：
	-- 例如，如果 lhs="<leader>ff" 在 normal 模式下已被 lazy 插件声明，
	-- 则从 modes 中移除 "n"，避免重复绑定。
	modes = vim.tbl_filter(function(m)
		-- keys:have(lhs, m) 检查在模式 m 下，lhs 是否已被 lazy 处理器接管
		return not (keys.have and keys:have(lhs, m))
	end, modes)

	-- 只有当还有未被 lazy 接管的模式时，才创建实际的快捷键映射
	if #modes > 0 then
		opts = opts or {} -- 确保 opts 是一个表

		-- 默认启用 silent（静默模式），除非用户显式设置 opts.silent = false
		opts.silent = opts.silent ~= false

		-- 如果设置了 remap 且当前**不是**在 VS Code Neovim 环境中，
		-- 则移除 remap 选项（因为大多数情况下不需要递归映射，且可能引发问题）
		if opts.remap and not vim.g.vscode then
			---@diagnostic disable-next-line: no-unknown
			opts.remap = nil -- 静默移除，避免警告
		end

		-- 使用 Snacks.keymap.set（可能是对 vim.keymap.set 的进一步封装）来设置快捷键
		vim.keymap.set(modes, lhs, rhs, opts)
	end
end

map = M.safe_keymap_set

-- ESC
-- keymap.set("i", "jk", "<Esc>")
map({ "i" }, "jk", "<Esc>")

-- better up/down
--
-- 在普通模式和可视模式下，重映射 "j" 键：
-- 当没有输入数字前缀（v:count == 0）时，使用 "gj"（按屏幕行移动）；
-- 否则使用原生 "j"（按文件逻辑行移动），实现更自然的长行滚动体验。
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })

-- 在普通模式和可视模式下，重映射方向键 ↓：
-- 行为与 "j" 一致——无前缀时按屏幕行向下，有前缀时按逻辑行向下。
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })

-- 在普通模式和可视模式下，重映射 "k" 键：
-- 当没有输入数字前缀（v:count == 0）时，使用 "gk"（按屏幕行向上）；
-- 否则使用原生 "k"（按文件逻辑行向上），避免在折行（wrap）时跳行不连贯。
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- 在普通模式和可视模式下，重映射方向键 ↑：
-- 行为与 "k" 一致——无前缀时按屏幕行向上，有前缀时按逻辑行向上。
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-S-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-S-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-S-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move Lines
map("n", "<C-S-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<C-S-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<C-S-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<C-S-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<C-S-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<C-S-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
-- 使用 Shift+h（即大写 H）切换到上一个缓冲区（buffer）
-- 适合习惯用左右手配合操作的用户（h/l 常用于左右导航）
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })

-- 使用 Shift+l（即大写 L）切换到下一个缓冲区
-- 与 <S-h> 对称，形成左右切换的直观操作
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- 使用 [b 快捷键切换到上一个缓冲区
-- 遵循 Vim 社区常见约定：[ 和 ] 用于“向前/向后”导航（如 [d, ]d）
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })

-- 使用 ]b 快捷键切换到下一个缓冲区
-- 与 [b 配对，语义清晰，易于记忆
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- 使用 <leader>bb 快速切换回最近访问的另一个缓冲区（# 表示交替缓冲区）
-- 类似于 Ctrl+Tab 在 IDE 中的效果：在两个常用文件间快速来回
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

-- 使用 <leader>`（反引号）作为 <leader>bb 的替代快捷键
-- 反引号 ` 在 Vim 中传统上就代表“交替文件”（#），此处延续这一惯例
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
	Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
	Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
	vim.cmd("noh")
	PixVim.cmp.actions.snippet_stop()
	return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
	"n",
	"<leader>ur",
	"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
	{ desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

--keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- lazy
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- location list
map("n", "<leader>xl", function()
	local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Location List" })

-- quickfix list
map("n", "<leader>xq", function()
	local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- formatting
map({ "n", "x" }, "<leader>cf", function()
	PixVim.format({ force = true })
end, { desc = "Format" })

-- diagnostic
local diagnostic_goto = function(next, severity)
	return function()
		vim.diagnostic.jump({
			count = (next and 1 or -1) * vim.v.count1,
			severity = severity and vim.diagnostic.severity[severity] or nil,
			float = true,
		})
	end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- 完整的诊断控制快捷键
vim.keymap.set("n", "<leader>td", function()
	local bufnr = 0
	local is_enabled = vim.diagnostic.is_enabled({ bufnr = bufnr })

	if is_enabled then
		vim.diagnostic.enable(false, { bufnr = bufnr })
		vim.notify("Diagnostics disabled", vim.log.levels.INFO)
	else
		vim.diagnostic.enable(true, { bufnr = bufnr })
		vim.notify("Diagnostics enabled", vim.log.levels.INFO)
	end
end, { desc = "Toggle diagnostics" })

-- floating terminal
map("n", "<leader>fT", function()
	Snacks.terminal()
end, { desc = "Terminal (cwd)" })
map("n", "<leader>ft", function()
	Snacks.terminal(nil, { cwd = PixVim.root() })
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function()
	Snacks.terminal(nil, { cwd = PixVim.root() })
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-_>", function()
	Snacks.terminal(nil, { cwd = PixVim.root() })
end, { desc = "which_key_ignore" })
