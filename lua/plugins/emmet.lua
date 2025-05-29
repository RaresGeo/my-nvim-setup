return {
	"dcampos/cmp-emmet-vim",
	dependencies = { "mattn/emmet-vim" },
	ft = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact" },
	config = function()
		vim.g.user_emmet_install_global = 0
		vim.g.user_emmet_settings = {
			variables = {
				lang = "en",
			},
		}
	end,
}
