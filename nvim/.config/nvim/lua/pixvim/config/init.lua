-- 1. 先定义 PixVim 工具模块,是util模块, 为其他模块提供基础
_G.PixVim = require("pixvim.util")

---@class LazyVimConfig: LazyVimOptions
local M = {}
M.version = "0.0.1" -- x-release-please-version
PixVim.config = M

---@class LazyVimOptions
local defaults = {
	-- colorscheme can be a string like `catppuccin` or a function that will load the colorscheme
	---@type string|fun()
	colorscheme = function()
		require("tokyonight").load()
	end,
	-- load the default settings
	defaults = {
		autocmds = true, -- lazyvim.config.autocmds
		keymaps = true, -- lazyvim.config.keymaps
		-- lazyvim.config.options can't be configured here since that's loaded before lazyvim setup
		-- if you want to disable loading options, add `package.loaded["lazyvim.config.options"] = true` to the top of your init.lua
	},

  -- icons used by other plugins
  -- stylua: ignore
  icons = {
    misc = {
      dots = "󰇘",
    },
    ft = {
      octo = " ",
      gh = " ",
      ["markdown.gh"] = " ",
    },
    dap = {
      Stopped             = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
      Breakpoint          = " ",
      BreakpointCondition = " ",
      BreakpointRejected  = { " ", "DiagnosticError" },
      LogPoint            = ".>",
    },
    diagnostics = {
      Error = " ",
      Warn  = " ",
      Hint  = " ",
      Info  = " ",
    },
    git = {
      added    = " ",
      modified = " ",
      removed  = " ",
    },
    kinds = {
      Array         = " ",
      Boolean       = "󰨙 ",
      Class         = " ",
      Codeium       = "󰘦 ",
      Color         = " ",
      Control       = " ",
      Collapsed     = " ",
      Constant      = "󰏿 ",
      Constructor   = " ",
      Copilot       = " ",
      Enum          = " ",
      EnumMember    = " ",
      Event         = " ",
      Field         = " ",
      File          = " ",
      Folder        = " ",
      Function      = "󰊕 ",
      Interface     = " ",
      Key           = " ",
      Keyword       = " ",
      Method        = "󰊕 ",
      Module        = " ",
      Namespace     = "󰦮 ",
      Null          = " ",
      Number        = "󰎠 ",
      Object        = " ",
      Operator      = " ",
      Package       = " ",
      Property      = " ",
      Reference     = " ",
      Snippet       = "󱄽 ",
      String        = " ",
      Struct        = "󰆼 ",
      Supermaven    = " ",
      TabNine       = "󰏚 ",
      Text          = " ",
      TypeParameter = " ",
      Unit          = " ",
      Value         = " ",
      Variable      = "󰀫 ",
    },
  },
	---@type table<string, string[]|boolean>?
	kind_filter = {
		default = {
			"Class",
			"Constructor",
			"Enum",
			"Field",
			"Function",
			"Interface",
			"Method",
			"Module",
			"Namespace",
			"Package",
			"Property",
			"Struct",
			"Trait",
		},
		markdown = false,
		help = false,
		-- you can specify a different filter for each filetype
		lua = {
			"Class",
			"Constructor",
			"Enum",
			"Field",
			"Function",
			"Interface",
			"Method",
			"Module",
			"Namespace",
			-- "Package", -- remove package since luals uses it for control flow structures
			"Property",
			"Struct",
			"Trait",
		},
	},
}

M.json = {
	version = 8,
	loaded = false,
	path = vim.g.lazyvim_json or vim.fn.stdpath("config") .. "/lazyvim.json",
	data = {
		version = nil, ---@type number?
		install_version = nil, ---@type number?
		extras = {}, ---@type string[]
	},
}

function M.json.load()
	M.json.loaded = true
	local f = io.open(M.json.path, "r")
	if f then
		local data = f:read("*a")
		f:close()
		local ok, json = pcall(vim.json.decode, data, { luanil = { object = true, array = true } })
		if ok then
			M.json.data = vim.tbl_deep_extend("force", M.json.data, json or {})
			if M.json.data.version ~= M.json.version then
				LazyVim.json.migrate()
			end
		end
	else
		M.json.data.install_version = M.json.version
	end
end

---@type LazyVimOptions
local options
local lazy_clipboard

-- pixvim setup
---@param opts? LazyVimOptions
function M.setup(opts)
	options = vim.tbl_deep_extend("force", defaults, opts or {}) or {}

	-- autocmds can be loaded lazily when not opening a file
	local lazy_autocmds = vim.fn.argc(-1) == 0
	if not lazy_autocmds then
		M.load("autocmds")
	end

	local group = vim.api.nvim_create_augroup("PixVim", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "VeryLazy",
		callback = function()
			if lazy_autocmds then
				M.load("autocmds")
			end
			M.load("keymaps")
			if lazy_clipboard ~= nil then
				vim.opt.clipboard = lazy_clipboard
			end

			PixVim.format.setup()
			PixVim.root.setup()

			vim.api.nvim_create_user_command("LazyHealth", function()
				vim.cmd([[Lazy! load all]])
				vim.cmd([[checkhealth]])
			end, { desc = "Load all plugins and run :checkhealth" })

			if vim.g.lazyvim_check_order == false then
				return
			end

			-- Check lazy.nvim import order
			local imports = require("lazy.core.config").spec.modules
			local function find(pat, last)
				for i = last and #imports or 1, last and 1 or #imports, last and -1 or 1 do
					if imports[i]:find(pat) then
						return i
					end
				end
			end
			local pixvim_plugins = find("^pixvim%.plugins$")
			local plugins = find("^plugins$") or math.huge
			if pixvim_plugins ~= 1 then
				local msg = {
					"The order of your `lazy.nvim` imports is incorrect:",
					"- `pixvim.plugins` should be first",
					"- followed by any `pixvim.plugins.extras`",
					"- and finally your own `plugins`",
					"",
					"If you think you know what you're doing, you can disable this check with:",
					"```lua",
					"vim.g.pixvim = false",
					"```",
				}
				vim.notify(table.concat(msg, "\n"), "warn", { title = "PixVim" })
			end
		end,
	})
end

M._options = {} ---@type vim.wo|vim.bo

-- 加载模块
---@param name "autocmds" | "options" | "keymaps"
function M.load(name)
	local function _load(mod)
		-- 定义加载模块的方法，默认从缓存中加载
		if require("lazy.core.cache").find(mod)[1] then
			PixVim.try(function()
				require(mod)
			end, { msg = "Failed loading " .. mod })
		end
	end
	-- LazyVim拼接Autocmds，Options，Keymaps
	local pattern = "PixVim" .. name:sub(1, 1):upper() .. name:sub(2)
	-- always load lazyvim, then user file
	-- 确保 LazyVim 插件配置在用户配置之前加载
	-- 加载配置并触发 User 事件
	if M.defaults[name] or name == "options" then
		_load("pixvim.config." .. name)
		vim.api.nvim_exec_autocmds("User", { pattern = pattern .. "Defaults", modeline = false })
	end

	-- 在用户配置
	_load("config." .. name)
	-- lazy界面，触发重绘逻辑
	if vim.bo.filetype == "lazy" then
		-- HACK: PixVim may have overwritten options of the Lazy ui, so reset this here
		vim.cmd([[do VimResized]])
	end
	-- 触发事件
	vim.api.nvim_exec_autocmds("User", { pattern = pattern, modeline = false })
end

M.did_init = false

-- config init
-- (1). lazy_notify()
-- (2). 加载 options 选项配置
-- (3). 保存默认选项intentexpr, foldmethod, foldexpr
-- (4). 保存粘贴板指令，设为“”，加快启动速度
-- (5). 插件启动
function M.init()
	-- 避免重复初始化
	if M.did_init then
		return
	end
	M.did_init = true

	-- lazy.vim delay notifications.
	PixVim.lazy_notify()

	-- load options here, before lazy init while sourcing plugin modules
	-- this is needed to make sure options will be correctly applied
	-- after installing missing plugins
	M.load("options")

	-- save some options to track defaults
	-- 保存选项到临时变量
	M._options.indentexpr = vim.o.indentexpr
	M._options.foldmethod = vim.o.foldmethod
	M._options.foldexpr = vim.o.foldexpr

	-- 加快启动速,先把粘贴板保存起来，再设为""
	lazy_clipboard = vim.opt.clipboard:get()
	vim.opt.clipboard = ""

	-- 插件启动
	PixVim.plugin.setup()

	-- 启动pixvim
	M.setup()
end

setmetatable(M, {
	__index = function(_, key)
		if options == nil then
			return vim.deepcopy(defaults)[key]
		end
		---@cast options PixVimConfig
		return options[key]
	end,
})

return M
