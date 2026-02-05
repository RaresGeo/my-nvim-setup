return {
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = {
		"pyproject.toml",
		"setup.py",
		"setup.cfg",
		"requirements.txt",
		"Pipfile",
		"pyrightconfig.json",
		".git",
	},
	capabilities = _G.lsp_capabilities,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "standard",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
			},
		},
	},
}
