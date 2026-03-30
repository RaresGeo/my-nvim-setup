return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
	keys = {
		{ "<leader>dv", "<cmd>DiffviewOpen<cr>", desc = "Open diff view (unstaged changes)" },
		{ "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
		{ "<leader>dq", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
	},
	opts = {
		view = {
			default = { layout = "diff2_horizontal" },
		},
	},
}
