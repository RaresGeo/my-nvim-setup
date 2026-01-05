local function organize_imports_go()
	local params = vim.lsp.util.make_range_params()
	params.context = { only = { "source.organizeImports" } }
	local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
	for _, res in pairs(result or {}) do
		for _, action in pairs(res.result or {}) do
			if action.edit then
				vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
			end
		end
	end
end

return {
	capabilities = _G.lsp_capabilities,
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { "go.work", "go.mod", ".git" },
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = organize_imports_go,
		})

		if client.name == "gopls" then
			vim.keymap.set('n', '<leader>fs', function()
				-- Search backwards for lines not starting with space, tab, or #
				local pattern = '^[^ \\t#]'
				local line = vim.fn.search(pattern, 'bn')

				if line == 0 then
					vim.notify('Couldn\'t find start of function', vim.log.levels.WARN)
					return
				end

				vim.cmd('normal! ' .. line .. 'G')
			end, { desc = 'Go to start of function' })
		end
	end,
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = {
				unusedparams = true,
			},
			["formatting.gofumpt"] = true,
			["ui.diagnostic.staticcheck"] = true,
			["ui.inlayhint.hints"] = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
		},
	},
}
