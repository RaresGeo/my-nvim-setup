return {
	cmd = { 'vscode-json-language-server', '--stdio' },
	filetypes = { 'json', 'jsonc' },
	capabilities = _G.lsp_capabilities,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
}
