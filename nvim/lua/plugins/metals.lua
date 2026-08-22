return {
	{
		"scalameta/nvim-metals",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		ft = { "scala", "sbt", "java" },
		opts = function()
			local metals_config = require("metals").bare_config()

			-- Example of settings
			metals_config.settings = {
				showImplicitArguments = true,
				showImplicitConversionsAndClasses = true,
				showInferredType = true,
				superMethodLensesEnabled = true,
				enableSemanticHighlighting = false,
			}

			-- LSP mappings handled by lsp.lua, but we can add Metals-specific ones here
			metals_config.on_attach = function(client, bufnr)
				-- Metals specific keymaps
				vim.keymap.set("n", "<leader>mt", function()
					require("metals.tvp").toggle_tree_view()
				end, { buffer = bufnr, desc = "Toggle Metals tree view" })

				vim.keymap.set("n", "<leader>mr", function()
					require("metals.tvp").reveal_in_tree()
				end, { buffer = bufnr, desc = "Reveal in Metals tree" })

				vim.keymap.set("n", "<leader>mw", function()
					require("telescope").extensions.metals.commands()
				end, { buffer = bufnr, desc = "Metals worksheet commands" })
			end

			return metals_config
		end,
		config = function(self, metals_config)
			local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = self.ft,
				callback = function()
					require("metals").initialize_or_attach(metals_config)
				end,
				group = nvim_metals_group,
			})
		end,
	},
}
