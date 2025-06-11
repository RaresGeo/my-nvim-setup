return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		local autopairs = require("nvim-autopairs")

		autopairs.setup({
			check_ts = true, -- Enable treesitter integration
			ts_config = {
				lua = { "string" }, -- Don't auto-pair in lua string treesitter nodes
				javascript = { "string", "template_string" },
				java = false, -- Don't check treesitter on java
			},
			disable_filetype = { "TelescopePrompt", "vim" },
			disable_in_macro = true, -- Disable when recording macros
			disable_in_visualblock = false,
			disable_in_replace_mode = true,
			ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
			enable_moveright = true,
			enable_afterquote = true, -- Add bracket pairs after quote
			enable_check_bracket_line = true, -- Check bracket in same line
			enable_bracket_in_quote = true,
			enable_abbr = false, -- Trigger abbreviations
			break_undo = true, -- Switch for basic rule break undo sequence
			check_comma = true,
			map_cr = true,
			map_bs = true, -- Map the <BS> key
			map_c_h = false, -- Map the <C-h> key to delete a pair
			map_c_w = false, -- Map <C-w> to delete a pair if possible
		})

		-- Custom rules for specific languages
		local Rule = require("nvim-autopairs.rule")
		local ts_conds = require("nvim-autopairs.ts-conds")

		-- Add spaces inside brackets for JavaScript/TypeScript
		autopairs.add_rules({
			Rule(" ", " ")
				:with_pair(function(opts)
					local pair = opts.line:sub(opts.col - 1, opts.col)
					return vim.tbl_contains({ "()", "[]", "{}" }, pair)
				end)
				:with_move(function(opts)
					return opts.char == " "
				end)
				:with_cr(function(opts)
					return false
				end)
				:with_del(function(opts)
					local col = vim.api.nvim_win_get_cursor(0)[2]
					local context = opts.line:sub(col - 1, col + 2)
					return vim.tbl_contains({ "(  )", "[  ]", "{  }" }, context)
				end),
		})
		--
	end,
}
