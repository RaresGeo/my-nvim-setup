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
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				client.request_sync("workspace/executeCommand", {
					command = "ruff.applyOrganizeImports",
					arguments = { { uri = vim.uri_from_bufnr(bufnr), version = vim.lsp.util.buf_versions[bufnr] } },
				}, 3000, bufnr)
			end,
		})
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
