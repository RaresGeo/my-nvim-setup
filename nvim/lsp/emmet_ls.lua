return {
	capabilities = _G.lsp_capabilities,
	filetypes = {
		"html",
		"css",
		"scss",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
	},
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
	init_options = {
		html = {
			options = {
				["bem.enabled"] = true,
			},
		},
	},
}
