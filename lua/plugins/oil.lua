return {
	"stevearc/oil.nvim",
	opts = {},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			view_options = {
				show_hidden = true,
			},
		})

		-- Keymap to open oil
		vim.keymap.set("n", "<leader>e", ":Oil<CR>", { desc = "Open file explorer" })
	end,
}
