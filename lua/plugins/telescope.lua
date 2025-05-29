return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("telescope").setup({
			defaults = {
				-- Use ripgrep for file_ignore_patterns and faster searching
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden", -- Include hidden files
					"--glob=!.git/*", -- But exclude .git directory
				},
				file_ignore_patterns = {
					"node_modules/",
					".git/",
					"dist/",
					"build/",
					"target/",
					"*.lock",
				},
			},
			pickers = {
				find_files = {
					find_command = {
						"rg",
						"--files",
						"--hidden", -- Include hidden files
						"--glob=!.git/*", -- But exclude .git directory
					},
				},
				live_grep = {
					additional_args = function()
						return { "--hidden", "--glob=!.git/*" }
					end,
				},
			},
		})

		-- Recent Files functionality
		local recent_files = {}
		local max_recent_files = 10

		-- Function to add file to recent list
		local function add_recent_file(filepath)
			if not filepath or filepath == "" then
				return
			end

			-- Remove if already exists to move it to front
			for i, file in ipairs(recent_files) do
				if file == filepath then
					table.remove(recent_files, i)
					break
				end
			end

			-- Add to front
			table.insert(recent_files, 1, filepath)

			-- Keep only max_recent_files
			if #recent_files > max_recent_files then
				recent_files = { unpack(recent_files, 1, max_recent_files) }
			end
		end

		-- Function to show recent files picker
		local function show_recent_files_picker()
			if #recent_files == 0 then
				print("No recent files")
				return
			end

			local pickers = require("telescope.pickers")
			local finders = require("telescope.finders")
			local conf = require("telescope.config").values
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			-- Prepare the entries for telescope
			local entries = {}
			for i, filepath in ipairs(recent_files) do
				local filename = vim.fn.fnamemodify(filepath, ":t")
				local relative_path = vim.fn.fnamemodify(filepath, ":.")
				table.insert(entries, {
					display = string.format("%d: %s (%s)", i, filename, relative_path),
					ordinal = filename .. " " .. relative_path,
					value = filepath,
					index = i,
				})
			end

			pickers
				.new({}, {
					prompt_title = "Recent Files",
					finder = finders.new_table({
						results = entries,
						entry_maker = function(entry)
							return {
								display = entry.display,
								ordinal = entry.ordinal,
								value = entry.value,
								index = entry.index,
								path = entry.value, -- Required for preview
							}
						end,
					}),
					sorter = conf.generic_sorter({}),
					previewer = conf.file_previewer({}), -- Add file preview
					default_selection_index = 2, -- Start with second entry selected
					attach_mappings = function(prompt_bufnr, map)
						actions.select_default:replace(function()
							local selection = action_state.get_selected_entry()
							actions.close(prompt_bufnr)
							if selection then
								vim.cmd("edit " .. selection.value)
								-- Move selected file to front of recent list
								add_recent_file(selection.value)
							end
						end)
						return true
					end,
				})
				:find()
		end

		-- Auto command to track file opens
		local augroup = vim.api.nvim_create_augroup("RecentFiles", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			group = augroup,
			pattern = "*",
			callback = function()
				local filepath = vim.fn.expand("%:p")
				-- Only track actual files (not empty buffers, help, etc.)
				if filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
					-- Check if it's a regular file (not help, terminal, etc.)
					local buftype = vim.bo.buftype
					local filetype = vim.bo.filetype
					if buftype == "" and filetype ~= "help" and filetype ~= "qf" then
						add_recent_file(filepath)
					end
				end
			end,
		})

		-- Make functions available globally
		_G.RecentFiles = {
			show_picker = show_recent_files_picker,
			add_file = add_recent_file,
			get_recent = function()
				return recent_files
			end,
			clear = function()
				recent_files = {}
			end,
		}

		-- Key mappings
		vim.keymap.set("n", "<C-;>", show_recent_files_picker, { desc = "Show recent files picker" })
		vim.keymap.set("n", "<leader><Tab>", show_recent_files_picker, { desc = "Show recent files picker" })
	end,
}
