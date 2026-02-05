return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = { "tsx", "javascript", "typescript", "lua", "vim", "html", "css", "python" },
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
