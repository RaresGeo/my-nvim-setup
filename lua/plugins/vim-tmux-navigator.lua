local buf_was_terminal = {}

local function tmux_navigate_from_terminal(cmd)
    return function()
        buf_was_terminal[vim.api.nvim_get_current_buf()] = true
        vim.cmd("stopinsert")
        vim.cmd(cmd)
    end
end

local function tmux_navigate_from_normal(cmd)
    return function()
        buf_was_terminal[vim.api.nvim_get_current_buf()] = false
        vim.cmd(cmd)
    end
end

return {
    "christoomey/vim-tmux-navigator",
    init = function()
        vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
        vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("TmuxNavTermRestore", { clear = true }),
            callback = function()
                local buf = vim.api.nvim_get_current_buf()
                if vim.bo[buf].buftype == "terminal" and buf_was_terminal[buf] then
                    vim.cmd.startinsert()
                end
            end,
        })
    end,
    cmd = {
        "TmuxNavigateLeft",
        "TmuxNavigateDown",
        "TmuxNavigateUp",
        "TmuxNavigateRight",
        "TmuxNavigatePrevious",
        "TmuxNavigatorProcessList",
    },
    keys = {
        -- Normal mode
        { "<c-h>", tmux_navigate_from_normal("TmuxNavigateLeft") },
        { "<c-j>", tmux_navigate_from_normal("TmuxNavigateDown") },
        { "<c-k>", tmux_navigate_from_normal("TmuxNavigateUp") },
        { "<c-l>", tmux_navigate_from_normal("TmuxNavigateRight") },
        -- Terminal mode
        { "<c-h>", tmux_navigate_from_terminal("TmuxNavigateLeft"),  mode = "t" },
        { "<c-j>", tmux_navigate_from_terminal("TmuxNavigateDown"),  mode = "t" },
        { "<c-k>", tmux_navigate_from_terminal("TmuxNavigateUp"),    mode = "t" },
        { "<c-l>", tmux_navigate_from_terminal("TmuxNavigateRight"), mode = "t" },
    },
}
