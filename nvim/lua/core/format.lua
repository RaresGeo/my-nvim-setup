-- vim.lsp.buf.format() runs every attached client that can format, one after
-- another, and each one computes its edits against the buffer as it was before
-- any of them ran -- so with ts_ls and oxfmt both attached the second set of
-- edits lands on ranges the first has already moved. Pick one instead, and
-- prefer the dedicated formatter: it is the one that agrees with what the
-- project's own lint:fix produces, which is the whole point of having it.
local M = {}

local dedicated = {
    oxfmt = true,
}

function M.format(opts)
    opts = opts or {}
    local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = "textDocument/formatting",
    })

    local has_dedicated = false
    for _, client in ipairs(clients) do
        if dedicated[client.name] then
            has_dedicated = true
            break
        end
    end

    -- No dedicated formatter in this project: the LSP is still better than
    -- leaving the buffer alone, so fall back to the old behaviour untouched.
    vim.lsp.buf.format(vim.tbl_extend("force", opts, {
        bufnr = bufnr,
        filter = function(client)
            return not has_dedicated or dedicated[client.name] == true
        end,
    }))
end

return M
