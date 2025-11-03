return {
	"akinsho/git-conflict.nvim",
	version = "*",
	config = function()
		require("git-conflict").setup({
			default_mappings = true, -- disable buffer local mapping created by this plugin
			default_commands = true, -- disable commands created by this plugin
			disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
			list_opener = "copen", -- command or function to open the conflicts list
			highlights = { -- They must have background color, otherwise the default color will be used
				incoming = "DiffAdd",
				current = "DiffText",
			},
		})
	end,
	keys = {
		{ "<leader>gco", "<cmd>GitConflictChooseOurs<cr>",   desc = "Choose ours (current branch)" },
		{ "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose theirs (incoming branch)" },
		{ "<leader>gcb", "<cmd>GitConflictChooseBoth<cr>",   desc = "Choose both changes" },
		{ "<leader>gc0", "<cmd>GitConflictChooseNone<cr>",   desc = "Choose none (delete both)" },
		{ "]x",          "<cmd>GitConflictNextConflict<cr>", desc = "Next conflict" },
		{ "[x",          "<cmd>GitConflictPrevConflict<cr>", desc = "Previous conflict" },
		{ "<leader>gcl", "<cmd>GitConflictListQf<cr>",       desc = "List conflicts in quickfix" },
	},
}
