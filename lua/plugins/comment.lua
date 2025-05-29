return {
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		config = function()
			vim.g.skip_ts_context_commentstring_module = true
			require("ts_context_commentstring").setup({})
		end,
	},
	{
		"numToStr/Comment.nvim",
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		config = function()
			require("Comment").setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
				-- Custom keymaps
				mappings = {
					basic = true, -- Enable default mappings (gcc, gc, etc.)
					extra = false, -- Don't enable extra mappings
				},
			})

			-- Custom Ctrl+/ keymaps that work properly with Comment.nvim
			local api = require("Comment.api")

			vim.keymap.set("n", "<C-_>", api.toggle.linewise.current, {
				noremap = true,
				silent = true,
				desc = "Toggle comment",
			})

			-- For visual mode, use the Comment.nvim's proper visual mode function
			vim.keymap.set("x", "<C-_>", function()
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
				api.toggle.linewise(vim.fn.visualmode())
			end, {
				noremap = true,
				silent = true,
				desc = "Toggle comment",
			})
		end,
	},
}
