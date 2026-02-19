-- Autocommands

-- Disable paste mode when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
    desc = "Disable paste mode on insert",
    callback = function()
        vim.opt.paste = false
    end,
})

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
    desc = "Format buffer before saving",
    callback = function()
        vim.lsp.buf.format()
    end,
})

