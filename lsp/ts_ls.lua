local function organize_imports_ts()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	local is_node = false

	for _, client in ipairs(clients) do
		if client.name == "ts_ls" then
			is_node = true
			break
		end
	end

	if is_node then
		local params = {
			command = "_typescript.organizeImports",
			arguments = { vim.api.nvim_buf_get_name(0) },
		}

		vim.lsp.buf_request(0, "workspace/executeCommand", params, function(err, _)
			if err then
				vim.notify("Error organizing imports: " .. vim.inspect(err), vim.log.levels.ERROR)
			end
		end)
	end
end

return {
	capabilities = _G.lsp_capabilities,
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_markers = { "package.json" },
	workspace_required = true,
	single_file_support = false,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
	commands = {
		OrganizeImports = {
			organize_imports_ts,
			description = "Organize Imports",
		},
	},
}
