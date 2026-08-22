return {
	cmd = { 'metals' },
	capabilities = _G.lsp_capabilities,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)

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
}
