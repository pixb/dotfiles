-- 需求：获取项目的根目录

-- 设置元表,调用函数第一个参数的 get()
local M = setmetatable({}, {
	__call = function(m, ...)
		return m.get(...)
	end,
})

function M.is_win()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

M.spec = { "lsp", { ".git", "lua" }, "cwd" }

M.detectors = {}

function M.detectors.cwd()
	return { vim.uv.cwd() }
end

---@param patterns string[]|string
function M.detectors.pattern(buf, patterns)
  patterns = type(patterns) == "string" and { patterns } or patterns
  local path = M.bufpath(buf) or vim.uv.cwd()
  local pattern = vim.fs.find(function(name)
    for _, p in ipairs(patterns) do
      if name == p then
        return true
      end
      if p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$") then
        return true
      end
    end
    return false
  end, { path = path, upward = true })[1]
  return pattern and { vim.fs.dirname(pattern) } or {}
end

function M.bufpath(buf)
  return M.realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function M.realpath(path)
  if path == "" or path == nil then
    return nil
  end
  path = vim.fn.has("win32") == 0 and vim.uv.fs_realpath(path) or path
  return PixVim.norm(path)
end

-- 缓存
---@type table<number, string>
M.cache = {}

---@param spec LazyRootSpec
---@return LazyRootFn
function M.resolve(spec)
	if M.detectors[spec] then
		return M.detectors[spec]
	elseif type(spec) == "function" then
		return spec
	end
	return function(buf)
		return M.detectors.pattern(buf, spec)
	end
end

function M.detect(opts)
	-- 防止nil
	opts = opts or {}
	-- 取 spec
	opts.spec = opts.spec or type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec
	-- 取buf
	opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf
	local ret = {} ---@type LazyRoot[]
	for _, spec in ipairs(opts.spec) do
		local paths = M.resolve(spec)(opts.buf)
		paths = paths or {}
		paths = type(paths) == "table" and paths or { paths }
		local roots = {} ---@type string[]
		for _, p in ipairs(paths) do
			local pp = M.realpath(p)
			if pp and not vim.tbl_contains(roots, pp) then
				roots[#roots + 1] = pp
			end
		end
		table.sort(roots, function(a, b)
			return #a > #b
		end)
		if #roots > 0 then
			ret[#ret + 1] = { spec = spec, paths = roots }
			if opts.all == false then
				break
			end
		end
	end
	return ret
end

function M.info()
	-- 检查全局设置 root_spec or 取默认M.spec
	local spec = type(vim.g.root_spec) == "table" and vim.g.root_spec or M.sepc
	local roots = M.detect({ all = true })

	local lines = {} ---@type string[]
	local first = true
	for _, root in ipairs(roots) do
		for _, path in ipairs(root.paths) do
			lines[#lines + 1] = ("- [%s] `%s` **(%s)**"):format(
				first and "x" or " ",
				path,
				type(root.spec) == "table" and table.concat(root.spec, ", ") or root.spec
			)
			first = false
		end
	end
	lines[#lines + 1] = "```lua"
	lines[#lines + 1] = "vim.g.root_spec = " .. vim.inspect(spec)
	lines[#lines + 1] = "```"
	LazyVim.info(lines, { title = "LazyVim Roots" })
	return roots[1] and roots[1].paths[1] or vim.uv.cwd()
end

-- 启动
-- config/init.lua setup() 调用
function M.setup()
	-- 创建用户命令PixRoot
	-- 打印root信息
	vim.api.nvim_create_user_command("PixRoot", function()
		PixVim.root.info()
	end, { desc = "PixVim roots for the current buffer" })

	-- FIX: doesn't properly clear cache in neo-tree `set_root` (which should happen presumably on `DirChanged`),
	-- probably because the event is triggered in the neo-tree buffer, therefore add `BufEnter`
	-- Maybe this is too frequent on `BufEnter` and something else should be done instead??
	vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
		group = vim.api.nvim_create_augroup("lazyvim_root_cache", { clear = true }),
		callback = function(event)
			M.cache[event.buf] = nil
		end,
	})
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
---@param opts? {normalize?:boolean, buf?:number}
---@return string
function M.get(opts)
	opts = opts or {}
	-- 获取buf
	local buf = opts.buf or vim.api.nvim_get_current_buf()
	local ret = M.cache[buf]
	if not ret then
		local roots = M.detect({ all = false, buf = buf })
		ret = roots[1] and roots[1].paths[1] or vim.uv.cwd()
		M.cache[buf] = ret
	end
	if opts and opts.normalize then
		return ret
	end
	return PixVim.is_win() and ret:gsub("/", "\\") or ret
end

function M.git()
	local root = M.get()
	local git_root = vim.fs.find(".git", { path = root, upward = true })[1]
	local ret = git_root and vim.fn.fnamemodify(git_root, ":h") or root
	return ret
end

return M
