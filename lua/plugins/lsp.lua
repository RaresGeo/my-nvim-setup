local function organize_imports_ts()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	local is_node = false

	for _, client in ipairs(clients) do
		if client.name == "ts_ls" then
			is_node = true
			break
		end
	end

	if is_node then
		local params = {
			command = "_typescript.organizeImports",
			arguments = { vim.api.nvim_buf_get_name(0) },
		}

		vim.lsp.buf_request(0, "workspace/executeCommand", params, function(err, _)
			if err then
				vim.notify("Error organizing imports: " .. vim.inspect(err), vim.log.levels.ERROR)
			end
		end)
	end
end

local function organize_imports_go()
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*.go",
		callback = function()
			local params = vim.lsp.util.make_range_params()
			params.context = { only = { "source.organizeImports" } }
			local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
			for _, res in pairs(result or {}) do
				for _, action in pairs(res.result or {}) do
					if action.edit then
						vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
					end
				end
			end
		end,
	})
end

return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"saghen/blink.cmp",
	},
	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		---@diagnostic disable-next-line: unused-local
		local on_attach = function(client, bufnr)
			local opts = { buffer = bufnr, silent = true }

			-- Navigation
			vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)
			vim.keymap.set("n", "td", "<cmd>Telescope lsp_type_definitions<cr>", opts)
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
			vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<cr>", opts)
			vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, opts)

			-- Code actions
			vim.keymap.set("n", "<leader>ca", "<cmd>Telescope lsp_code_actions<cr>", opts)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

			-- Diagnostics
			vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
			vim.keymap.set("n", "<leader>q", "<cmd>Telescope diagnostics bufnr=0<cr>", opts) -- current buffer diagnostics

			-- Format on save
			-- if client.supports_method("textDocument/formatting") then
			-- 	vim.api.nvim_create_autocmd("BufWritePre", {
			-- 		buffer = bufnr,
			-- 		callback = function()
			-- 			vim.lsp.buf.format({ async = false })
			-- 		end,
			-- 	})
			-- end
		end

		vim.lsp.enable("ts_ls")

		vim.lsp.config("ts_ls", {
			cmd = { "typescript-language-server", "--stdio" },
			capabilities = capabilities,
			on_attach = on_attach,
			---@diagnostic disable-next-line: unused-local
			root_dir = function(bufnr, on_dir)
				local root_path = vim.fs.find("package.json", {
					upward = true,
					type = "file",
					path = vim.fn.getcwd(),
				})[1]

				if root_path then
					on_dir(vim.fn.fnamemodify(root_path, ":h"))
				end
			end,
			workspace_required = true,
			single_file_support = false,
			commands = {
				OrganizeImports = {
					organize_imports_ts,
					description = "Organize Imports",
				},
			},
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
			},
		})

		vim.lsp.enable("denols")

		vim.lsp.config("denols", {
			cmd = { "deno", "lsp" },
			cmd_env = { NO_COLOR = true },
			capabilities = capabilities,
			on_attach = on_attach,
			---@diagnostic disable-next-line: unused-local
			root_dir = function(bufnr, on_dir)
				local root_path = vim.fs.find("deno.json", {
					upward = true,
					type = "file",
					path = vim.fn.getcwd(),
				})[1]

				if root_path then
					on_dir(vim.fn.fnamemodify(root_path, ":h"))
				end
			end,
			workspace_required = true,
		})

		vim.lsp.enable("emmet_ls")

		vim.lsp.config("emmet_ls", {
			capabilities = vim.tbl_extend("force", capabilities, {
				documentFormattingProvider = false,
				documentRangeFormattingProvider = false,
			}),
			on_attach = on_attach,
			filetypes = {
				"html",
				"css",
				"scss",
				"javascriptreact",
				"typescriptreact",
				"vue",
				"svelte",
			},
			init_options = {
				html = {
					options = {
						["bem.enabled"] = true,
					},
				},
			},
		})

		vim.lsp.enable("gopls")

		vim.lsp.config("gopls", {
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = organize_imports_go,
				})
			end,
			capabilities = capabilities,
			cmd = { "gopls" },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_markers = { "go.work", "go.mod", ".git" },
			settings = {
				gopls = {
					completeUnimported = true,
					usePlaceholders = true,
					analyses = {
						unusedparams = true,
					},
					["formatting.gofumpt"] = true,
					["ui.diagnostic.staticcheck"] = true,
					["ui.inlayhint.hints"] = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
				},
			},
		})

		vim.lsp.enable("metals")

		vim.lsp.config("metals", {
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)

				vim.keymap.set("n", "<leader>mc", function()
					require("telescope").extensions.metals.commands()
				end, { buffer = bufnr, desc = "Metals commands" })

				vim.keymap.set("n", "<leader>mi", function()
					vim.lsp.buf.execute_command({ command = "metals.reveal-in-tree" })
				end, { buffer = bufnr, desc = "Metals reveal in tree" })
			end,
			settings = {
				metals = {
					serverVersion = "latest.snapshot",
					showImplicitArguments = true,
					showImplicitConversionsAndClasses = true,
					showInferredType = true,
					superMethodLensesEnabled = true,
					enableSemanticHighlighting = false,
				},
			},
			init_options = {
				statusBarProvider = "off",
			},
		})

		vim.lsp.enable("lua_ls")

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
					telemetry = {
						enable = false,
					},
				},
			},
		})

		vim.lsp.enable("pylsp")

		vim.lsp.config("pylsp", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.enable("solidity_ls")

		vim.lsp.config("solidity_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = { 'vscode-solidity-server', '--stdio' },
			filetypes = { 'solidity' },
			root_markers = {
				'hardhat.config.js',
				'hardhat.config.ts',
				'foundry.toml',
				'remappings.txt',
				'truffle.js',
				'truffle-config.js',
				'ape-config.yaml',
				'.git',
				'package.json',
			},
		})

		vim.diagnostic.config({
			virtual_text = {
				prefix = "●",
			},
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.HINT] = "",
					[vim.diagnostic.severity.INFO] = "",
				},
			},
			underline = true,
			update_in_insert = false,
			severity_sort = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "if_many",
				header = "",
				prefix = "",
			},
		})

		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#ff6b6b", bg = "NONE", italic = true })
		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#feca57", bg = "NONE", italic = true })
		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#48dbfb", bg = "NONE", italic = true })
		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#54a0ff", bg = "NONE", italic = true })

		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
		})

		vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
			border = "rounded",
		})
	end,
}
