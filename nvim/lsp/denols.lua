return {
	capabilities = _G.lsp_capabilities,
	cmd = { "deno", "lsp" },
	cmd_env = { NO_COLOR = true },
	root_markers = { "deno.json" },
	workspace_required = true,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
		if client.name == "denols" then
			vim.opt_local.shiftwidth = 2
			vim.opt_local.tabstop = 2
			vim.opt_local.expandtab = true
		end
	end,
}
