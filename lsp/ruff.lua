return {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_markers = {
		"pyproject.toml",
		"ruff.toml",
		".ruff.toml",
		".git",
	},
	capabilities = _G.lsp_capabilities,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
		client.server_capabilities.hoverProvider = false
	end,
	init_options = {
		settings = {
			lineLength = 100,
			lint = {
				enable = true,
			},
		},
	},
}
