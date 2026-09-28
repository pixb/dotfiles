---@module 'snacks'

---@type LazyPicker
local picker = {
	name = "snacks",
	commands = {
		files = "files",
		live_grep = "grep",
		oldfiles = "recent",
	},

	---@param source string
	---@param opts? snacks.picker.Config
	open = function(source, opts)
		return Snacks.picker.pick(source, opts)
	end,
}
if not PixVim.pick.register(picker) then
	return {}
end

-- Terminal Mappings
local function term_nav(dir)
	---@param self snacks.terminal
	return function(self)
		return self:is_floating() and "<c-" .. dir .. ">" or vim.schedule(function()
			vim.cmd.wincmd(dir)
		end)
	end
end

return {
	-- 文件浏览器
	{
		desc = "Snacks File Explorer",
		"folke/snacks.nvim",
		-- 加载的优先级
		priority = 1000,
		lazy = false,
		opts = { explorer = {} },
		config = function(_, opts)
			-- local notify = vim.notify
			require("snacks").setup(opts)
			-- HACK: restore vim.notify after snacks setup and let noice.nvim take over
			-- this is needed to have early notifications show up in noice history
			-- if PixVim.has("noice.nvim") then
			--   vim.notify = notify
			-- end
		end,
		-- 配置按键提示
		keys = {
			{
				"<leader>fe",
				function()
					Snacks.explorer({ cwd = PixVim.root() })
				end,
				desc = "Explorer Snacks (root dir)",
			},
			{
				"<leader>fE",
				function()
					Snacks.explorer()
				end,
				desc = "Explorer Snacks (cwd)",
			},
			{ "<leader>e", "<leader>fe", desc = "Explorer Snacks (root dir)", remap = true },
			{ "<leader>E", "<leader>fE", desc = "Explorer Snacks (cwd)", remap = true },
		},
	},

	{
		"snacks.nvim",
		opts = {
			-- 缩进可视化
			indent = { enabled = true },
			-- 输入框美化
			input = { enabled = true },
			-- 通知框美化
			notifier = { enabled = true },
			-- 作用域模块
			-- 代码作用域分析
			-- 高亮缩进线
			scope = { enabled = true },
			-- 平滑滚动
			scroll = { enabled = true },
			-- 状态栏，自定义状态栏
			statuscolumn = { enabled = false }, -- we set this in options.lua
			-- 切换功能
			toggle = { map = PixVim.safe_keymap_set },
			-- 单词高亮
			words = { enabled = true },
		},
    -- stylua: ignore
    keys = {
      { "<leader>n", function()
        if Snacks.config.picker and Snacks.config.picker.enabled then
          Snacks.picker.notifications()
        else
          Snacks.notifier.show_history()
        end
      end, desc = "Notification History" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    },
	},

	{
		"snacks.nvim",
		opts = {
			-- 仪表板
			dashboard = {
				preset = {
					pick = function(cmd, opts)
						return PixVim.pick(cmd, opts)()
					end,
					header = [[
          ██████╗ ██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗
          ██╔══██╗██║╚██╗██╔╝██║   ██║██║████╗ ████║
          ██████╔╝██║ ╚███╔╝ ██║   ██║██║██╔████╔██║
          ██╔═══╝ ██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║
          ██║     ██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║
          ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            -- { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
				},
			},
		},
	},
	-- 配置导航器,模糊搜索，文件选择，快速选择
	{
		"folke/snacks.nvim",
		opts = {
			-- 配置选择器
			picker = {
				win = {
					input = {
						keys = {
							["<a-c>"] = {
								"toggle_cwd",
								mode = { "n", "i" },
							},
						},
					},
				},
				-- 定义触发动作
				actions = {
					---@param p snacks.Picker
					toggle_cwd = function(p)
						local root = PixVim.root({ buf = p.input.filter.current_buf, normalize = true })
						local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
						local current = p:cwd()
						p:set_cwd(current == root and cwd or root)
						p:find()
					end,
				},
			},
		},
    -- stylua: ignore
    keys = {
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>/", PixVim.pick("grep"), desc = "Grep (Root Dir)" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader><space>", PixVim.pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      -- find
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "Buffers (all)" },
      { "<leader>fc", PixVim.pick.config_files(), desc = "Find Config File" },
      { "<leader>ff", PixVim.pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>fF", PixVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
      { "<leader>fr", PixVim.pick("oldfiles"), desc = "Recent" },
      { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      -- git
      { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" },
      { "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, desc = "Git Diff (origin)" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
      { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
      { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
      { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
      { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
      { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
      -- Grep
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
      { "<leader>sg", PixVim.pick("live_grep"), desc = "Grep (Root Dir)" },
      { "<leader>sG", PixVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      { "<leader>sw", PixVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
      { "<leader>sW", PixVim.pick("grep_word", { root = false }), desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
      -- search
      { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
      { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undotree" },
      -- ui
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    },
	},
	-- Snacks utils 使用snack扩展功能。
	{
		"snacks.nvim",
		opts = {
			bigfile = { enabled = true },
			quickfile = { enabled = true },
			terminal = {
				win = {
					keys = {
						nav_h = { "<C-h>", term_nav("h"), desc = "Go to Left Window", expr = true, mode = "t" },
						nav_j = { "<C-j>", term_nav("j"), desc = "Go to Lower Window", expr = true, mode = "t" },
						nav_k = { "<C-k>", term_nav("k"), desc = "Go to Upper Window", expr = true, mode = "t" },
						nav_l = { "<C-l>", term_nav("l"), desc = "Go to Right Window", expr = true, mode = "t" },
					},
				},
			},
		},
    -- stylua: ignore
    keys = {
      { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Buffer" },
    },
	},
}
