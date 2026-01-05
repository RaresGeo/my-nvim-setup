return {
	cmd = { 'pylsp' },
	filetypes = { 'python' },
	root_markers = {
		'pyproject.toml',
		'setup.py',
		'setup.cfg',
		'requirements.txt',
		'Pipfile',
		'.git',
	},
	capabilities = _G.lsp_capabilities,
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
	settings = {
		pylsp = {
			plugins = {
				isort = { enabled = false },
				ruff = { enabled = false },
				autopep8 = { enabled = false },
				yapf = { enabled = false },
				mypy = {
					enabled = true,
					live_mode = true,
					strict = false,
				},
				pycodestyle = {
					enabled = false
				}
			},
		},
	},
}
