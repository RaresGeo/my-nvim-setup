return {
	cmd = { 'lua-language-server' },
	filetypes = { 'lua' },
	root_markers = {
		'.emmyrc.json',
		'.luarc.json',
		'.luarc.jsonc',
		'.luacheckrc',
		'.stylua.toml',
		'stylua.toml',
		'selene.toml',
		'selene.yml',
		'.git',
	},
	capabilities = _G.lsp_capabilities,
	on_attach = function(client, bufnr)
		print("attached to lua thing")
		_G.lsp_on_attach(client, bufnr)
	end,
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			telemetry = {
				enable = false,
			},
		},
	},
}
