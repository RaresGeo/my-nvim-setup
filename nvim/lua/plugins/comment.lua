return {
	{
		-- Context-aware commentstring (e.g. proper comments inside jsx/tsx).
		-- Neovim 0.10+ has built-in commenting (gc/gcc/gbc), so we no longer
		-- need a dedicated commenting plugin; we just teach the native
		-- commenting which commentstring to use via vim.filetype.get_option.
		"JoosepAlviste/nvim-ts-context-commentstring",
		lazy = false,
		config = function()
			vim.g.skip_ts_context_commentstring_module = true

			require("ts_context_commentstring").setup({
				enable_autocmd = false,
			})

			-- Hook Neovim's built-in commenting so it asks
			-- ts_context_commentstring for the correct commentstring at the
			-- cursor position (embedded languages, jsx/tsx, etc.).
			local get_option = vim.filetype.get_option
			vim.filetype.get_option = function(filetype, option)
				return option == "commentstring"
						and require("ts_context_commentstring.internal").calculate_commentstring()
					or get_option(filetype, option)
			end

			-- Custom Ctrl+/ keymaps on top of native commenting.
			--
			-- Both spellings are mapped because which one arrives depends
			-- on the terminal: <C-/> where it speaks the Kitty keyboard
			-- protocol and can encode the Ctrl losslessly, <C-_> (0x1F)
			-- where it falls back to the C0 control character. On macOS
			-- neither happens on its own -- Alacritty writes a bare `/`,
			-- which opens a search -- so macos/alacritty/alacritty.toml
			-- binds Ctrl+/ to 0x1F explicitly.
			local comment_keys = { "<C-/>", "<C-_>" }

			for _, key in ipairs(comment_keys) do
				-- remap = true so it resolves the built-in gcc/gc mappings.
				vim.keymap.set("n", key, "gcc", {
					remap = true,
					silent = true,
					desc = "Toggle comment",
				})

				vim.keymap.set("x", key, "gc", {
					remap = true,
					silent = true,
					desc = "Toggle comment",
				})
			end
		end,
	},
}
