return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			config = function()
				require("luasnip.loaders.from_vscode").lazy_load()

				-- Add the snippet leave function
				local function leave_snippet()
					if
					    ((vim.v.event.old_mode == "s" and vim.v.event.new_mode == "n") or vim.v.event.old_mode == "i")
					    and require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
					    and not require("luasnip").session.jump_active
					then
						require("luasnip").unlink_current()
					end
				end

				-- Set up the autocmd to stop snippets when leaving to normal mode
				vim.api.nvim_create_autocmd("ModeChanged", {
					callback = leave_snippet,
				})
			end,
		},
	},
	version = "1.*",
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		snippets = { preset = "luasnip" },

		keymap = {
			preset = "enter",
			["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
			["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
		},

		appearance = {
			nerd_font_variant = "mono",
		},

		completion = {
			documentation = { auto_show = true },
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
