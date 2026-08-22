return {
	capabilities = _G.lsp_capabilities,
	cmd = { 'vscode-solidity-server', '--stdio' },
	filetypes = { 'solidity' },
	root_markers = {
		'hardhat.config.js',
		'hardhat.config.ts',
		'foundry.toml',
		'remappings.txt',
		'truffle.js',
		'truffle-config.js',
		'ape-config.yaml',
		'.git',
		'package.json',
	},
	on_attach = function(client, bufnr)
		_G.lsp_on_attach(client, bufnr)
	end,
}
