return {
    cmd = { 'intelephense', '--stdio' },
    filetypes = { 'php' },
    root_markers = { 'composer.json', '.git' },
    capabilities = _G.lsp_capabilities,
    on_attach = _G.lsp_on_attach,
}
