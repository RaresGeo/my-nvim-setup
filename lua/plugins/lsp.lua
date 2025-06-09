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
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
			vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, opts)

			-- Code actions
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

			-- Diagnostics
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
			vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
			vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)

			-- Format on save for TypeScript/JavaScript
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
			on_attach = on_attach,
			root_dir = function(fname)
				if is_deno_project(fname) then
					return nil -- Explicitly prevent ts_ls in Deno projects
				end
				return lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json")(
				fname)
			end,
			single_file_support = false, -- Prevent ts_ls from starting on single files
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
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = " ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
			underline = true,
			update_in_insert = false,
			severity_sort = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})

		-- Configure LSP handlers
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
		})

		vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
			border = "rounded",
		})
	end,
}
