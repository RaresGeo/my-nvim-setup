return {
    "christoomey/vim-tmux-navigator",
    init = function()
        vim.g.tmux_navigator_no_mappings = 1
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
        { "<c-h>", "<cmd>:TmuxNavigateLeft<cr>" },
        { "<c-j>", "<cmd>:TmuxNavigateDown<cr>" },
        { "<c-k>", "<cmd>:TmuxNavigateUp<cr>" },
        { "<c-l>", "<cmd>:TmuxNavigateRight<cr>" },
        -- Terminal mode (exit terminal mode first, then navigate)
        { "<c-h>", "<C-\\><C-n>:TmuxNavigateLeft<cr>",  mode = "t" },
        { "<c-j>", "<C-\\><C-n>:TmuxNavigateDown<cr>",  mode = "t" },
        { "<c-k>", "<C-\\><C-n>:TmuxNavigateUp<cr>",    mode = "t" },
        { "<c-l>", "<C-\\><C-n>:TmuxNavigateRight<cr>", mode = "t" },
    },
}
