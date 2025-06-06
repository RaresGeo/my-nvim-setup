return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSP completion source
			"hrsh7th/cmp-buffer", -- Buffer completion source
			"hrsh7th/cmp-path", -- Path completion source
			"hrsh7th/cmp-cmdline", -- Command line completion
			"L3MON4D3/LuaSnip", -- Snippet engine
			"saadparwaiz1/cmp_luasnip", -- Snippet completion source
			"rafamadriz/friendly-snippets", -- Predefined snippets
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Load predefined snippets
			require("luasnip.loaders.from_vscode").lazy_load()

			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

			cmp.setup({
				performance = {
					debounce = 0,
					throttle = 10,
					fetching_timeout = 200,
					confirm_resolve_timeout = 80,
					async_budget = 1,
					max_view_entries = 50,
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				sources = cmp.config.sources({
					{
						name = "nvim_lsp",
						max_item_count = 20,
					},
					{
						name = "luasnip",
						max_item_count = 5,
					},
					{
						name = "emmet_vim",
						max_item_count = 5,
					},
				}, {
					{
						name = "buffer",
						max_item_count = 5,
						keyword_length = 3,
					},
					{
						name = "path",
						max_item_count = 10,
					},
				}),
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							local entry = cmp.get_selected_entry()
							if entry then
								cmp.confirm({
									behavior = cmp.ConfirmBehavior.Replace,
									select = true,
								})
							else
								fallback()
							end
						else
							fallback()
						end
					end),

					-- Tab and Shift-Tab for snippet navigation
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				formatting = {
					format = function(entry, vim_item)
						-- Add icons for different completion types
						local icons = {
							Text = "",
							Method = "",
							Function = "",
							Constructor = "",
							Field = "",
							Variable = "",
							Class = "",
							Interface = "",
							Module = "",
							Property = "",
							Unit = "",
							Value = "",
							Enum = "",
							Keyword = "",
							Snippet = "",
							Color = "",
							File = "",
							Reference = "",
							Folder = "",
							EnumMember = "",
							Constant = "",
							Struct = "",
							Event = "",
							Operator = "",
							TypeParameter = "",
						}

						vim_item.kind = string.format("%s %s", icons[vim_item.kind] or "",
							vim_item.kind)
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
						})[entry.source.name]

						return vim_item
					end,
				},
			})

			-- Command line completion
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})
		end,
	},
}
