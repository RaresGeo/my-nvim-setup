return {
	"saghen/blink.cmp",
	dependencies = { "rafamadriz/friendly-snippets", "L3MON4D3/LuaSnip", version = "v2.*" },
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
