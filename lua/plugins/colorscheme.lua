return {
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("kanagawa")
		end,
	},
	{
		"sainnhe/everforest",
		priority = 999,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 998,
	},
}
