return {
	capabilities = _G.lsp_capabilities,
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", "rust-project.json", ".git" },
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
			},
			check = {
				command = "clippy",
			},
			procMacro = {
				enable = true,
			},
		},
	},
}
