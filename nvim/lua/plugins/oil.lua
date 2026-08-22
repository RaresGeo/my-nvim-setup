return {
	"stevearc/oil.nvim",
	opts = {},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			view_options = {
				show_hidden = true,
			},
			keymaps = {
				-- Disable default C-h/C-l to let vim-tmux-navigator work
				["<C-h>"] = false,
				["<C-l>"] = false,
			},
		})

		-- Keymap to open oil
		vim.keymap.set("n", "<leader>e", ":Oil<CR>", { desc = "Open file explorer" })
	end,
}
