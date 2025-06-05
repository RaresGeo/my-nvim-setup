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

				-- Check if file has unsaved changes
				local has_unsaved_changes = false
				local bufnr = vim.fn.bufnr(filepath)
				if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
					has_unsaved_changes = vim.bo[bufnr].modified
				end

				local modified_indicator = has_unsaved_changes and "* " or " "

				table.insert(entries, {
					display = string.format("%s%d: %s (%s)", modified_indicator, i, filename,
						relative_path),
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
			callback = function(ev)
				local bufnr = ev.buf
				local filepath = vim.api.nvim_buf_get_name(bufnr)
				local buftype = vim.bo[bufnr].buftype

				-- Only track regular files, not terminals
				if filepath ~= "" and vim.fn.filereadable(filepath) == 1 and buftype ~= "terminal" then
					local filetype = vim.bo[bufnr].filetype
					if buftype == "" and filetype ~= "help" and filetype ~= "qf" then
						add_recent_file(filepath)
					end
				end
			end,
		})

		local function toggle_recent_terminal_file()
			print("Toggling recent terminal")
			local current_buftype = vim.bo.buftype

			if current_buftype == "terminal" then
				-- We're in a terminal, find most recent non-terminal file from recent_files
				for _, filepath in ipairs(recent_files) do
					vim.cmd("edit " .. filepath)
					return
				end
				print("No recent files found")
				vim.cmd("Oil")
			else
				-- We're in a regular file, find most recent terminal from all buffers
				local terminal_bufs = {}
				for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "terminal" then
						table.insert(terminal_bufs, {
							bufnr = bufnr,
							lastused = vim.fn.getbufinfo(bufnr)[1].lastused,
						})
					end
				end

				if #terminal_bufs > 0 then
					-- Sort by most recently used
					table.sort(terminal_bufs, function(a, b)
						return a.lastused > b.lastused
					end)
					vim.cmd("buffer " .. terminal_bufs[1].bufnr)
					vim.cmd("startinsert")
					return
				end

				print("No recent terminals found, opening a new one")
				open_terminal_in_current_dir()
			end
		end
		-- Make functions available globally
		_G.RecentFiles = {
			show_picker = show_recent_files_picker,
			add_file = add_recent_file,
			toggle_terminal_file = toggle_recent_terminal_file,
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
		vim.keymap.set("n", "<leader>`", toggle_recent_terminal_file,
			{ desc = "Toggle between recent terminal and file" })
		vim.keymap.set("t", "<leader>`", function()
			-- Exit terminal mode first, then call the function
			vim.cmd("stopinsert")
			toggle_recent_terminal_file()
		end, { desc = "Toggle between recent terminal and file" })
	end,
}
