-- 使用最新版的配置仍然需要配置这个插件，目的是统一管理配置
-- 参考 devdoc/00文档
return {
	"neovim/nvim-lspconfig",
	event = "VeryLazy",
	-- Allow users to extend the default LSP server keybindings
	-- Users can override or add keybindings in their config like:
	-- opts = { servers = { ["*"] = { keys = { { "gd", function() ... end } } } }
	opts_extend = { "servers.*.keys" },
	opts = function()
		---@class PluginLspOpts
		local ret = {
			diagnostics = {
				underline = true, -- 在出错文本下方显示下划线
				update_in_insert = false, -- 插入模式下不实时更新诊断信息
				virtual_text = {
					spacing = 4, -- 虚拟文本与行号之间的间距
					source = "if_many", -- 仅当同一行有多个诊断来源时才显示来源信息
					prefix = "●", -- 诊断信息前的符号
					-- 将 prefix 设为 "icons" 时，会根据诊断等级自动显示对应图标
					-- prefix = "icons",
				},
				severity_sort = true, -- 按诊断等级排序（错误 > 警告 > 信息 > 提示）
				-- 为诊断信息添加图标
				signs = {
					text = {
						-- 为不同严重程度的诊断设置图标
						[vim.diagnostic.severity.ERROR] = PixVim.config.icons.diagnostics.Error,
						[vim.diagnostic.severity.WARN] = PixVim.config.icons.diagnostics.Warn,
						[vim.diagnostic.severity.HINT] = PixVim.config.icons.diagnostics.Hint,
					},
				}, -- signs
			}, --diagnostics
			-- Enable this to enable the builtin LSP inlay hints on Neovim.
			-- Be aware that you also will need to properly configure your LSP server to
			-- provide the inlay hints.
			inlay_hints = {
				enabled = true, -- 启用内置 LSP 行内提示（inlay hints）
				exclude = { "vue" }, -- 不启用行内提示的文件类型列表
			}, -- inlay_hints
			-- Enable this to enable the builtin LSP code lenses on Neovim.
			-- Be aware that you also will need to properly configure your LSP server to
			-- provide the code lenses.
			codelens = { -- 启用内置 LSP 代码镜头（code lenses）
				enabled = false, -- 禁用代码镜头（code lenses）
			}, -- codelens
			-- Enable this to enable the builtin LSP folding on Neovim.
			-- Be aware that you also will need to properly configure your LSP server to
			-- provide the folds.
			folds = { -- 启用内置 LSP 折叠（folding）
				enabled = true, -- 启用内置 LSP 折叠（folding）
			}, --folds
			format = { -- 格式化选项
				formatting_options = nil, -- 格式化选项（参考 vim.lsp.buf.formatting_sync）
				timeout_ms = nil, -- 格式化超时时间（毫秒）
			}, --format
			-- LSP Server Settings
			-- Sets the default configuration for an LSP client (or all clients if the special name "*" is used).
			---@alias lazyvim.lsp.Config vim.lsp.Config|{mason?:boolean, enabled?:boolean, keys?:LazyKeysLspSpec[]}
			---@type table<string, lazyvim.lsp.Config|boolean>
			servers = { -- LSP 服务器配置
				-- configuration for all lsp servers
				["*"] = { -- 所有 LSP 服务器的默认配置
					capabilities = { -- LSP 客户端能力
						workspace = { -- 工作空间能力
							fileOperations = { -- 文件操作能力
								didRename = true, -- 支持文件重命名操作
								willRename = true, -- 支持文件重命名前的提示
							},
						},
					}, --capabilities
            -- stylua: ignore
            keys = {
              { "<leader>cl", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
              { "gd", vim.lsp.buf.definition, desc = "Goto Definition", has = "definition" },
              { "gr", vim.lsp.buf.references, desc = "References", nowait = true },
              { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
              { "gy", vim.lsp.buf.type_definition, desc = "Goto T[y]pe Definition" },
              { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
              { "K", function() return vim.lsp.buf.hover() end, desc = "Hover" },
              { "gK", function() return vim.lsp.buf.signature_help() end, desc = "Signature Help", has = "signatureHelp" },
              { "<c-k>", function() return vim.lsp.buf.signature_help() end, mode = "i", desc = "Signature Help", has = "signatureHelp" },
              { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "x" }, has = "codeAction" },
              { "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "x" }, has = "codeLens" },
              { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", mode = { "n" }, has = "codeLens" },
              { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", mode ={"n"}, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
              { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
              { "<leader>cA", PixVim.lsp.action.source, desc = "Source Action", has = "codeAction" },
              { "]]", function() Snacks.words.jump(vim.v.count1) end, has = "documentHighlight",
                desc = "Next Reference", enabled = function() return Snacks.words.is_enabled() end },
              { "[[", function() Snacks.words.jump(-vim.v.count1) end, has = "documentHighlight",
                desc = "Prev Reference", enabled = function() return Snacks.words.is_enabled() end },
              { "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, has = "documentHighlight",
                desc = "Next Reference", enabled = function() return Snacks.words.is_enabled() end },
              { "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, has = "documentHighlight",
                desc = "Prev Reference", enabled = function() return Snacks.words.is_enabled() end },
            }, -- keys
				}, --["*"]
				-- 禁用 stylua 服务器
				stylua = { enabled = false },
				lua_ls = { -- lua_ls 服务器的配置
					-- mason = false, -- set to false if you don't want this server to be installed with mason
					-- Use this to add any additional keymaps
					-- for specific lsp servers
					-- ---@type LazyKeysSpec[]
					-- keys = {},
					settings = {
						Lua = {
							workspace = {
								-- 禁用 lua_ls 对第三方库的检查
								checkThirdParty = false,
							},
							-- 启用 lua_ls 对代码镜头（code lenses）的支持
							codeLens = {
								enable = true,
							},
							completion = {
								callSnippet = "Replace",
							},
							doc = {
								privateName = { "^_" },
							},
							hint = {
								enable = true,
								setType = false,
								paramType = true,
								paramName = "Disable",
								semicolon = "Disable",
								arrayIndex = "Disable",
							}, -- hint
						}, -- Lua
					}, -- settings
				}, -- luals
			}, --servers
			-- you can do any additional lsp server setup here
			-- return true if you don't want this server to be setup with lspconfig
			---@type table<string, fun(server:string, opts: vim.lsp.Config):boolean?>
			setup = {
				-- example to setup with typescript.nvim
				-- tsserver = function(_, opts)
				--   require("typescript").setup({ server = opts })
				--   return true
				-- end,
				-- Specify * to use this function as a fallback for any server
				-- ["*"] = function(server, opts) end,
			}, -- setup
		} -- ret
		return ret
	end, -- opts function()
	config = function(_, opts)
		-- 现代写法：直接 enable 即可
		-- 以前需要 require('lspconfig').pyright.setup{}
		vim.lsp.enable("pyright")
		vim.lsp.enable("lua_ls")

		-- setup keymaps
		-- 为每个 LSP 服务器注册对应的快捷键
		for server, server_opts in pairs(opts.servers) do
			-- 仅当 server_opts 为表且包含 keys 字段时才进行绑定
			if type(server_opts) == "table" and server_opts.keys then
				-- 调用 LazyVim 的 keymaps 模块，为指定服务器设置快捷键
				-- name 为 nil 时表示对所有服务器生效（即 "*" 的情况）
				require("pixvim.lsp.keymaps").set({ name = server ~= "*" and server or nil }, server_opts.keys)
			end -- if
		end -- for
		-- inlay hints
		if opts.inlay_hints.enabled then
			Snacks.util.lsp.on({ method = "textDocument/inlayHint" }, function(buffer)
				if
					vim.api.nvim_buf_is_valid(buffer)
					and vim.bo[buffer].buftype == ""
					and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buffer].filetype)
				then
					vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
				end
			end)
		end -- end inlay hints
		-- folds
		if opts.folds.enabled then
			Snacks.util.lsp.on({ method = "textDocument/foldingRange" }, function()
				if PixVim.set_default("foldmethod", "expr") then
					PixVim.set_default("foldexpr", "v:lua.vim.lsp.foldexpr()")
				end
			end)
		end -- if folds
		-- code lens
		if opts.codelens.enabled and vim.lsp.codelens then
			Snacks.util.lsp.on({ method = "textDocument/codeLens" }, function(buffer)
				vim.lsp.codelens.refresh()
				vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
					buffer = buffer,
					callback = vim.lsp.codelens.refresh,
				})
			end)
		end --code lens
		-- diagnostics
		if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
			opts.diagnostics.virtual_text.prefix = function(diagnostic)
				local icons = PixVim.config.icons.diagnostics
				for d, icon in pairs(icons) do
					if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
						return icon
					end
				end
				return "●"
			end
		end -- diagnostics
		vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

		if opts.capabilities then
			PixVim.deprecate("lsp-config.opts.capabilities", "Use lsp-config.opts.servers['*'].capabilities instead")
			opts.servers["*"] = vim.tbl_deep_extend("force", opts.servers["*"] or {}, {
				capabilities = opts.capabilities,
			})
		end

		if opts.servers["*"] then
			vim.lsp.config("*", opts.servers["*"])
		end

		-- get all the servers that are available through mason-lspconfig
		local have_mason = PixVim.has("mason-lspconfig.nvim")
		local mason_all = have_mason
				and vim.tbl_keys(require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package)
			or {} --[[ @as string[] ]]
		local mason_exclude = {} ---@type string[]

		---@return boolean? exclude automatic setup
		local function configure(server)
			if server == "*" then
				return false
			end
			local sopts = opts.servers[server]
			sopts = sopts == true and {} or (not sopts) and { enabled = false } or sopts --[[@as lazyvim.lsp.Config]]

			if sopts.enabled == false then
				mason_exclude[#mason_exclude + 1] = server
				return
			end

			local use_mason = sopts.mason ~= false and vim.tbl_contains(mason_all, server)
			local setup = opts.setup[server] or opts.setup["*"]
			if setup and setup(server, sopts) then
				mason_exclude[#mason_exclude + 1] = server
			else
				vim.lsp.config(server, sopts) -- configure the server
				if not use_mason then
					vim.lsp.enable(server)
				end
			end
			return use_mason
		end

		local install = vim.tbl_filter(configure, vim.tbl_keys(opts.servers))
		if have_mason then
			require("mason-lspconfig").setup({
				ensure_installed = vim.list_extend(install, PixVim.opts("mason-lspconfig.nvim").ensure_installed or {}),
				automatic_enable = { exclude = mason_exclude },
			})
		end
	end, -- config
}
