return {
    cmd = { 'laravel-ls' },
    filetypes = { 'php', 'blade' },
    root_markers = { 'artisan' },
    capabilities = _G.lsp_capabilities,
    on_attach = _G.lsp_on_attach,
}
