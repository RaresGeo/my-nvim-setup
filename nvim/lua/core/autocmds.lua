-- Autocommands

-- Disable paste mode when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
    desc = "Disable paste mode on insert",
    callback = function()
        vim.opt.paste = false
    end,
})

-- Nix indentation
vim.api.nvim_create_autocmd("FileType", {
    pattern = "nix",
    desc = "2-space indentation for Nix files",
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
        vim.opt_local.expandtab = true
    end,
})

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
    desc = "Format buffer before saving",
    callback = function()
        vim.lsp.buf.format()
    end,
})

