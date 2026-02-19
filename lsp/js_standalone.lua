return {
    capabilities = _G.lsp_capabilities,
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = {
        "javascript",
    },
    root_dir = function(bufnr, cb)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then
            return
        end
        local found = vim.fs.find({ "package.json", "deno.json", "deno.jsonc" }, {
            path = vim.fs.dirname(fname),
            upward = true,
        })
        if #found > 0 then
            return
        end
        cb(vim.fs.dirname(fname))
    end,
    single_file_support = true,
    on_attach = function(client, bufnr)
        _G.lsp_on_attach(client, bufnr)
    end,
}
