return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    init = function()
        vim.api.nvim_create_autocmd('FileType', {
            callback = function()
                -- Enable treesitter highlighting and disable regex syntax
                pcall(vim.treesitter.start)
                -- Enable treesitter-based indentation
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
        local ensureInstalled = {
            "tsx", "javascript", "typescript", -- ts_ls, js_standalone, denols
            "lua", "vim", -- lua_ls
            "html", "css", "scss", -- html_ls, css_ls, emmet_ls, tailwind
            "python", -- pyright, ruff
            "php", "php_only", "blade", -- intelephense, laravel_ls
            "bash", -- bash
            "go", -- gopls
            "scala", -- metals
            "solidity", -- solidity_ls
            "json", -- jsonls
            "c", "cpp", "arduino", -- clangd, arduino_language_server
            "svelte", -- svelte
        }
        local alreadyInstalled = require('nvim-treesitter.config').get_installed()
        local parsersToInstall = vim.iter(ensureInstalled)
            :filter(function(parser)
                return not vim.tbl_contains(alreadyInstalled, parser)
            end)
            :totable()
        require('nvim-treesitter').install(parsersToInstall)
    end,
}
