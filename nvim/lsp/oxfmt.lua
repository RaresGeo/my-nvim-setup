-- oxfmt ships an LSP whose only capability is documentFormattingProvider, so it
-- exists purely to take formatting away from ts_ls. Going through the server
-- rather than piping to `oxfmt --stdin-filepath` is what makes it safe: stdin
-- mode applies no ignorePatterns, so it would happily rewrite the generated and
-- vendored files a project excludes on purpose. The server returns no edits for
-- those.
local oxfmt = require('core.oxfmt')

return {
    -- Both the config file and the binary are required, and the gate has to be
    -- here rather than in cmd: returning nil from cmd hangs the client instead
    -- of declining to start it. Not calling on_dir just leaves the buffer to
    -- whatever else attaches, which is what a project with no oxfmt installed
    -- should get.
    root_dir = function(bufnr, on_dir)
        local name = vim.api.nvim_buf_get_name(bufnr)
        local root = vim.fs.root(name ~= '' and name or vim.fn.getcwd(), '.oxfmtrc.json')
        if root and oxfmt.resolve(root) then
            on_dir(root)
        end
    end,
    cmd = function(dispatchers, config)
        local bin = oxfmt.resolve(config.root_dir)
        return vim.lsp.rpc.start({ bin, '--lsp' }, dispatchers, { cwd = config.root_dir })
    end,
    filetypes = {
        'javascript',
        'javascriptreact',
        'json',
        'jsonc',
        'typescript',
        'typescriptreact',
    },
    workspace_required = true,
    capabilities = _G.lsp_capabilities,
    on_attach = _G.lsp_on_attach,
}
