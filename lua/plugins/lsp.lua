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
		"saghen/blink.cmp", -- Changed from cmp-nvim-lsp to blink.cmp
	},
	config = function()
		local lspconfig = require("lspconfig")

		-- Enhanced capabilities for auto-completion using blink.cmp
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		-- Key mappings for LSP features
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
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
			vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
			vim.keymap.set("n", "<leader>q", "<cmd>Telescope diagnostics bufnr=0<cr>", opts) -- current buffer diagnostics

			-- Format on save
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({ async = false })
					end,
				})
			end
		end
		-- Helper function to check if we're in a Deno project
		local function is_deno_project(fname)
			return lspconfig.util.root_pattern("deno.json", "deno.jsonc")(fname) ~= nil
		end

		-- Emmet Language Server
		lspconfig.emmet_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = {
				"html",
				"css",
				"scss",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"svelte",
			},
			init_options = {
				html = {
					options = {
						-- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
						["bem.enabled"] = true,
					},
				},
			},
		})

		-- TypeScript/JavaScript Language Server
		lspconfig.ts_ls.setup({
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = organize_imports_ts,
				})
			end,
			root_dir = function(fname)
				if is_deno_project(fname) then
					return nil -- Explicitly prevent ts_ls in Deno projects
				end
				return lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json")(
				fname)
			end,
			single_file_support = false, -- Prevent ts_ls from starting on single files
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

		-- Deno Language Server
		lspconfig.denols.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
			single_file_support = false,
		})

		lspconfig.gopls.setup({
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
			root_dir = lspconfig.util.root_pattern("go.work", "go.mod", ".git"),
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

		-- Scala Language Server (Metals)
		lspconfig.metals.setup({
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)

				-- Metals specific commands
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
					enableSemanticHighlighting = false, -- Use treesitter instead
				},
			},
			init_options = {
				statusBarProvider = "off", -- Let nvim handle status
			},
		})

		-- Lua Language Server (for your Neovim config)
		lspconfig.lua_ls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" }, -- Recognize 'vim' global
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

		-- Configure diagnostics with modern sign configuration
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

		-- Configure LSP handlers
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
		})

		vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
			border = "rounded",
		})
	end,
}
