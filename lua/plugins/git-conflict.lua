return {
	"akinsho/git-conflict.nvim",
	version = "*",
	config = function()
		require("git-conflict").setup({
			default_mappings = true, -- disable buffer local mapping created by this plugin
			default_commands = true, -- disable commands created by this plugin
			disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
			list_opener = "copen", -- command or function to open the conflicts list
			highlights = { -- They must have background color, otherwise the default color will be used
				incoming = "DiffAdd",
				current = "DiffText",
			},
		})
	end,
	keys = {
		{ "<leader>gco", "<cmd>GitConflictChooseOurs<cr>",   desc = "Choose ours (current branch)" },
		{ "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose theirs (incoming branch)" },
		{ "<leader>gcb", "<cmd>GitConflictChooseBoth<cr>",   desc = "Choose both changes" },
		{ "<leader>gc0", "<cmd>GitConflictChooseNone<cr>",   desc = "Choose none (delete both)" },
		{ "]x",          "<cmd>GitConflictNextConflict<cr>", desc = "Next conflict" },
		{ "[x",          "<cmd>GitConflictPrevConflict<cr>", desc = "Previous conflict" },
		{
			"<leader>gcl",
			function()
				local handle = io.popen('git grep -n "^<<<<<<< " 2>/dev/null')
				if not handle then return end
				local result = handle:read("*a")
				handle:close()

				local entries = {}
				local seen = {}
				for line in result:gmatch("[^\r\n]+") do
					local file, lnum = line:match("^(.+):(%d+):")
					if file and lnum and not seen[file] then
						seen[file] = true
						table.insert(entries, string.format("%s:%s:1:", file, lnum))
					end
				end

				if #entries == 0 then
					vim.notify("No git conflicts found", vim.log.levels.INFO)
					return
				end

				local conf = require("telescope.config").values

				require("telescope.pickers").new({}, {
					prompt_title = "Git Conflicts",
					finder = require("telescope.finders").new_table({
						results = entries,
						entry_maker = require("telescope.make_entry").gen_from_vimgrep({}),
					}),
					sorter = conf.generic_sorter({}),
					previewer = conf.grep_previewer({}),
				}):find()
			end,
			desc = "List conflicts in Telescope",
		},
	},
}
