return {
    "saghen/blink.cmp",
    config = function()
        -- Configure blink.cmp
        require("blink.cmp").setup({
            keymap = {
                preset = "none",
                ["<C-space>"] = { "show", "hide" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<C-u>"] = { "scroll_documentation_up", "fallback" },
                ["<C-d>"] = { "scroll_documentation_down", "fallback" },
                ["<Tab>"] = {
                    function(cmp)
                        if cmp.snippet_active() and not cmp.is_active() then
                            return cmp.snippet_forward()
                        else
                            return cmp.select_next()
                        end
                    end,
                    "fallback",
                },
                ["<S-Tab>"] = {
                    function(cmp)
                        if cmp.snippet_active() and not cmp.is_active() then
                            return cmp.snippet_backward()
                        else
                            return cmp.select_prev()
                        end
                    end,
                    "fallback",
                },

                ["<CR>"] = { "accept", "fallback" },
            },
            completion = {
                trigger = {
                    show_on_insert_on_trigger_character = false,
                },
            },
        })

        local capabilities = require("blink.cmp").get_lsp_capabilities()

        -- Global on_attach function that will be used by all LSP configs
        ---@diagnostic disable-next-line: unused-local
        _G.lsp_on_attach = function(client, bufnr)
            local opts = { buffer = bufnr, silent = true }

            -- Navigation
            vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)
            vim.keymap.set("n", "td", "<cmd>Telescope lsp_type_definitions<cr>", opts)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<cr>", opts)
            vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, opts)

            -- Code actions
            vim.keymap.set("n", "<leader>ca", "<cmd>Telescope lsp_code_actions<cr>", opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

            -- Diagnostics
            vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "<leader>q", "<cmd>Telescope diagnostics bufnr=0<cr>", opts)
        end

        -- Global capabilities that will be merged with all LSP configs
        _G.lsp_capabilities = capabilities

        -- Enable all LSP servers (configs are in lsp/ directory)
        vim.lsp.enable("ts_ls")
        vim.lsp.enable("js_standalone")
        vim.lsp.enable("denols")
        vim.lsp.enable("emmet_ls")
        vim.lsp.enable("gopls")
        vim.lsp.enable("metals")
        vim.lsp.enable("lua_ls")
        vim.lsp.enable("pyright")
        vim.lsp.enable("ruff")
        vim.lsp.enable("solidity_ls")
        vim.lsp.enable("jsonls")
        vim.lsp.enable("clangd")
        vim.lsp.enable("arduino_language_server")
        vim.lsp.enable("html_ls")
        vim.lsp.enable("css_ls")

        -- Configure diagnostics UI
        vim.diagnostic.config({
            virtual_text = {
                prefix = "●",
            },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "",
                    [vim.diagnostic.severity.WARN] = "",
                    [vim.diagnostic.severity.HINT] = "",
                    [vim.diagnostic.severity.INFO] = "",
                },
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "if_many",
                header = "",
                prefix = "",
            },
        })

        -- Set diagnostic highlight colors
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#ff6b6b", bg = "NONE", italic = true })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#feca57", bg = "NONE", italic = true })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#48dbfb", bg = "NONE", italic = true })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#54a0ff", bg = "NONE", italic = true })

        -- Configure LSP floating window borders
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
            border = "rounded",
        })

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
            border = "rounded",
        })
    end,
}
