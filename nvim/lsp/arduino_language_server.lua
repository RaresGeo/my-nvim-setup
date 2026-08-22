return {
	capabilities = (function()
		local caps = vim.deepcopy(_G.lsp_capabilities)
		caps.textDocument = caps.textDocument or {}
		caps.workspace = caps.workspace or {}

		---@diagnostic disable-next-line: assign-type-mismatch
		caps.textDocument.semanticTokens = vim.NIL
		---@diagnostic disable-next-line: assign-type-mismatch
		caps.workspace = { semanticTokens = vim.NIL }
		return caps
	end)(),
	cmd = {
		"arduino-language-server",
	},
	filetypes = { "arduino" },
	root_dir = function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		on_dir(_G.root_pattern('*.ino')(fname))
	end,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
	on_exit = function(code, signal, client_id)
		-- Automatically restart the LSP if it crashes
		vim.schedule(function()
			local clients = vim.lsp.get_clients({ name = "arduino_language_server" })
			if #clients == 0 then
				-- Only restart if the server isn't already running
				vim.notify("Arduino LSP crashed, restarting...", vim.log.levels.WARN)
				vim.cmd("LspStart arduino_language_server")
			end
		end)
	end,
}
