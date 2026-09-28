return {
	recommended = function()
		return PixVim.extras.wants({
			ft = { "go", "gomod", "gowork", "gotmpl" },
			root = { "go.work", "go.mod" },
		})
	end,
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "go", "gomod", "gowork", "gosum" } },
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				gopls = {
					settings = {
						gopls = {
							-- 使用 gofumpt 进行代码格式化（比标准 gofmt 更严格）
							gofumpt = true,
							-- 代码镜头配置
							codelenses = {
								gc_details = false, -- 垃圾回收详细信息
								generate = true, -- 生成代码（如接口实现）
								regenerate_cgo = true, -- 重新生成 cgo 代码
								run_govulncheck = true, -- 运行漏洞检查
								test = true, -- 测试相关操作
								tidy = true, -- 整理 go.mod 文件
								upgrade_dependency = true, -- 升级依赖
								vendor = true, -- 依赖管理相关操作
							},
							-- 代码提示配置
							hints = {
								assignVariableTypes = true, -- 变量类型提示
								compositeLiteralFields = true, -- 复合字面量字段提示
								compositeLiteralTypes = true, -- 复合字面量类型提示
								constantValues = true, -- 常量值提示
								functionTypeParameters = true, -- 函数类型参数提示
								parameterNames = true, -- 参数名称提示
								rangeVariableTypes = true, -- 范围变量类型提示
							},
							-- 代码分析配置
							analyses = {
								nilness = true, -- nil 值检查
								unusedparams = true, -- 未使用参数检查
								unusedwrite = true, -- 未使用写入检查
								useany = true, -- any 类型使用检查
							},
							usePlaceholders = true, -- 在补全时使用占位符
							completeUnimported = true, -- 补全未导入的包
							staticcheck = true, -- 启用 staticcheck 代码检查
							-- 排除不需要分析的目录
							directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
							semanticTokens = true, -- 启用语义令牌（用于语法高亮）
						},
					},
				},
			},
			setup = {
				gopls = function(_, _)
					-- workaround for gopls not supporting semanticTokensProvider
					-- https://github.com/golang/go/issues/54531#issuecomment-1464982242
					Snacks.util.lsp.on({ name = "gopls" }, function(_, client)
						if not client.server_capabilities.semanticTokensProvider then
							local semantic = client.config.capabilities.textDocument.semanticTokens
							client.server_capabilities.semanticTokensProvider = {
								full = true,
								legend = {
									tokenTypes = semantic.tokenTypes,
									tokenModifiers = semantic.tokenModifiers,
								},
								range = true,
							}
						end
					end)
					-- end workaround
				end,
			},
		},
	},
	-- Ensure Go tools are installed
	{
		"mason-org/mason.nvim",
		opts = { ensure_installed = { "goimports", "gofumpt" } },
	},
	{
		"nvimtools/none-ls.nvim",
		optional = true,
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = { ensure_installed = { "gomodifytags", "impl" } },
			},
		},
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = vim.list_extend(opts.sources or {}, {
				nls.builtins.code_actions.gomodifytags,
				nls.builtins.code_actions.impl,
				nls.builtins.formatting.goimports,
				nls.builtins.formatting.gofumpt,
			})
		end,
	},
	-- Add linting
	{
		"mfussenegger/nvim-lint",
		optional = true,
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = { ensure_installed = { "golangci-lint" } },
			},
		},
		opts = {
			linters_by_ft = {
				go = { "golangcilint" },
			},
		},
	},
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = {
			formatters_by_ft = {
				go = { "goimports", "gofumpt" },
			},
		},
	},
	{
		"mfussenegger/nvim-dap",
		optional = true,
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = { ensure_installed = { "delve" } },
			},
			{
				"leoluz/nvim-dap-go",
				opts = {},
			},
		},
	},
	{
		"nvim-neotest/neotest",
		optional = true,
		dependencies = {
			"fredrikaverpil/neotest-golang",
		},
		opts = {
			adapters = {
				["neotest-golang"] = {
					-- Here we can set options for neotest-golang, e.g.
					-- go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
					dap_go_enabled = true, -- requires leoluz/nvim-dap-go
				},
			},
		},
	},

	-- Filetype icons
	{
		"nvim-mini/mini.icons",
		opts = {
			file = {
				[".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
			},
			filetype = {
				gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
			},
		},
	},
}
