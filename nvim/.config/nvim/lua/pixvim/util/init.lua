-- util init
local M = {}
M.deprecated = require("pixvim.util.deprecated")

-- 延迟加载 lazy.core.util
local function get_lazy_util()
	local ok, LazyUtil = pcall(require, "lazy.core.util")
	return ok and LazyUtil or {}
end

-- 元表实现动态加载
-- 当调用uitl动态加载util模块中的文件
-- 示例：PixVim = require("util") PixVim.root()
setmetatable(M, {
	-- 获取属性元方法
	__index = function(t, k)
		local LazyUtil = get_lazy_util()
		-- 如果 lazy.core.util 存在返回
		if LazyUtil[k] then
			return LazyUtil[k]
		end
		if M.deprecated[k] then
			return M.deprecated[k]()
		end
		t[k] = require("pixvim.util." .. k)
		M.deprecated.decorate(k, t[k])
		return t[k]
	end,
})

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
	if vim.api.nvim_get_mode().mode == "i" then
		vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
	end
end

---@param name string
function M.get_plugin(name)
	return require("lazy.core.config").spec.plugins[name]
end

---@param name string
---@param path string?
function M.get_plugin_path(name, path)
	local plugin = M.get_plugin(name)
	path = path and "/" .. path or ""
	return plugin and (plugin.dir .. path)
end

---@param plugin string
function M.has(plugin)
	return M.get_plugin(plugin) ~= nil
end

---@param name string
function M.opts(name)
	local plugin = M.get_plugin(name)
	if not plugin then
		return {}
	end
	local Plugin = require("lazy.core.plugin")
	return Plugin.values(plugin, "opts", false)
end

---@param opts? LazyNotifyOpts
function M.deprecate(old, new, opts)
	M.warn(
		("`%s` is deprecated. Please use `%s` instead"):format(old, new),
		vim.tbl_extend("force", {
			title = "PixVim",
			once = true,
			stacktrace = true,
			stacklevel = 6,
		}, opts or {})
	)
end

function M.is_win()
	return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@param fn fun()
function M.on_very_lazy(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function()
			fn()
		end,
	})
end

-- Safe wrapper around snacks to prevent errors when LazyVim is still installing
function M.statuscolumn()
	return package.loaded.snacks and require("snacks.statuscolumn").get() or ""
end

local _defaults = {} ---@type table<string, boolean>

-- Determines whether it's safe to set an option to a default value.
--
-- It will only set the option if:
-- * it is the same as the global value
-- * it's current value is a default value
-- * it was last set by a script in $VIMRUNTIME
---@param option string
---@param value string|number|boolean
---@return boolean was_set
function M.set_default(option, value)
	local l = vim.api.nvim_get_option_value(option, { scope = "local" })
	-- local g = PixVim.config._options[option] or vim.api.nvim_get_option_value(option, { scope = "global" })
	local g = vim.api.nvim_get_option_value(option, { scope = "global" })

	_defaults[("%s=%s"):format(option, value)] = true
	local key = ("%s=%s"):format(option, l)

	local source = ""
	if l ~= g and not _defaults[key] then
		-- Option does not match global and is not a default value
		-- Check if it was set by a script in $VIMRUNTIME
		local info = vim.api.nvim_get_option_info2(option, { scope = "local" })
		---@param e vim.fn.getscriptinfo.ret
		local scriptinfo = vim.tbl_filter(function(e)
			return e.sid == info.last_set_sid
		end, vim.fn.getscriptinfo())
		source = scriptinfo[1] and scriptinfo[1].name or ""
		local by_rtp = #scriptinfo == 1 and vim.startswith(scriptinfo[1].name, vim.fn.expand("$VIMRUNTIME"))
		if not by_rtp then
			if vim.g.lazyvim_debug_set_default then
				PixVim.warn(
					("Not setting option `%s` to `%q` because it was changed by a plugin."):format(option, value),
					{ title = "LazyVim", once = true }
				)
			end
			return false
		end
	end

	if vim.g.lazyvim_debug_set_default then
		PixVim.info({
			("Setting option `%s` to `%q`"):format(option, value),
			("Was: %q"):format(l),
			("Global: %q"):format(g),
			source ~= "" and ("Last set by: %s"):format(source) or "",
			"buf: " .. vim.api.nvim_buf_get_name(0),
		}, { title = "PixVim", once = true })
	end

	vim.api.nvim_set_option_value(option, value, { scope = "local" })
	return true
end

-- Wrapper around vim.keymap.set that will
-- not create a keymap if a lazy key handler exists.
-- It will also set `silent` to true by default.
function M.safe_keymap_set(mode, lhs, rhs, opts)
	local keys = require("lazy.core.handler").handlers.keys
	---@cast keys LazyKeysHandler
	local modes = type(mode) == "string" and { mode } or mode

	---@param m string
	modes = vim.tbl_filter(function(m)
		return not (keys.have and keys:have(lhs, m))
	end, modes)

	-- do not create the keymap if a lazy keys handler exists
	if #modes > 0 then
		opts = opts or {}
		opts.silent = opts.silent ~= false
		if opts.remap and not vim.g.vscode then
			---@diagnostic disable-next-line: no-unknown
			opts.remap = nil
		end
		Snacks.keymap.set(modes, lhs, rhs, opts)
	end
end

--- Override the default title for notifications.
for _, level in ipairs({ "info", "warn", "error" }) do
	M[level] = function(msg, opts)
		LazyUtil = get_lazy_util()
		opts = opts or {}
		opts.title = opts.title or "LazyVim"
		return LazyUtil[level](msg, opts)
	end
end

-- delay notifications till vim.notify was replaced or after 500ms
function M.lazy_notify()
	local notifs = {}
	local function temp(...)
		table.insert(notifs, vim.F.pack_len(...))
	end

	local orig = vim.notify
	vim.notify = temp

	local timer = vim.uv.new_timer()
	local check = assert(vim.uv.new_check())

	local replay = function()
		timer:stop()
		check:stop()
		if vim.notify == temp then
			vim.notify = orig -- put back the original notify if needed
		end
		vim.schedule(function()
			---@diagnostic disable-next-line: no-unknown
			for _, notif in ipairs(notifs) do
				vim.notify(vim.F.unpack_len(notif))
			end
		end)
	end

	-- wait till vim.notify has been replaced
	check:start(function()
		if vim.notify ~= temp then
			replay()
		end
	end)
	-- or if it took more than 500ms, then something went wrong
	timer:start(500, 0, replay)
end

function M.is_loaded(name)
	local Config = require("lazy.core.config")
	return Config.plugins[name] and Config.plugins[name]._.loaded
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
	if M.is_loaded(name) then
		fn(name)
	else
		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyLoad",
			callback = function(event)
				if event.data == name then
					fn(name)
					return true
				end
			end,
		})
	end
end

return M
