-- Disable arrow keys to force hjkl
vim.keymap.set('n', '<Left>', [[:echoe "Use h"<CR>]])
vim.keymap.set('n', '<Right>', [[:echoe "Use l"<CR>]])
vim.keymap.set('n', '<Up>', [[:echoe "Use k"<CR>]])
vim.keymap.set('n', '<Down>', [[:echoe "Use j"<CR>]])

vim.keymap.set('i', '<Left>', [[<ESC>:echoe "Use h"<CR>]])
vim.keymap.set('i', '<Right>', [[<ESC>:echoe "Use l"<CR>]])
vim.keymap.set('i', '<Up>', [[<ESC>:echoe "Use k"<CR>]])
vim.keymap.set('i', '<Down>', [[<ESC>:echoe "Use j"<CR>]])
-- General keymaps
vim.keymap.set("n", "<leader>f", function()
	vim.lsp.buf.format()
end, { desc = "Format buffer" })

vim.keymap.set("n", ",m", function()
	vim.cmd(":%s/\r//g")
end, { desc = "Clear ^M from pasting from Windows" })
vim.keymap.set("n", "<leader>l", function()
	vim.cmd("nohlsearch") -- Clear search highlighting
	vim.cmd("diffupdate") -- Refresh diff highlighting
	vim.cmd("redraw") -- Force redraw the screen
end, { desc = "Clear search highlighting and refresh screen" })

-- Harpoon keymaps
local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>a", function()
	harpoon:list():add()
end, { desc = "Add file to harpoon" })

vim.keymap.set("n", "<C-S-P>", function()
	harpoon:list():prev()
end, { desc = "Previous harpoon file" })

vim.keymap.set("n", "<C-S-N>", function()
	harpoon:list():next()
end, { desc = "Next harpoon file" })

vim.keymap.set("n", "<leader>tt", open_terminal_in_current_dir, { desc = "Open terminal in current file's directory" })

-- Telescope keymaps
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>ft", function()
	local terminal_bufs = {}
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[bufnr].buftype == "terminal" and vim.api.nvim_buf_is_loaded(bufnr) then
			table.insert(terminal_bufs, bufnr)
		end
	end

	if #terminal_bufs == 0 then
		print("No terminal buffers found")
		return
	end

	builtin.buffers({
		bufnr_width = 3,
		show_all_buffers = false,
		ignore_current_buffer = false,
		sort_mru = true,
		-- Pass only terminal buffer numbers
		default_text = "term://",
	})
end, { desc = "Find terminal buffers" })

local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
	local file_paths = {}
	for _, item in ipairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end

	require("telescope.pickers")
	    .new({}, {
		    prompt_title = "Harpoon",
		    finder = require("telescope.finders").new_table({
			    results = file_paths,
		    }),
		    previewer = conf.file_previewer({}),
		    sorter = conf.generic_sorter({}),
	    })
	    :find()
end

vim.keymap.set("n", "<C-e>", function()
	toggle_telescope(harpoon:list())
end, { desc = "Open harpoon window" })

vim.api.nvim_create_user_command("CpAbsPath", function(opts)
	local file = vim.fn.expand("%")
	if file == "" then
		vim.notify("No file name detected (unsaved buffer?)", vim.log.levels.ERROR)
		return
	end

	local abs_path = vim.fn.expand("%:p") -- Full absolute path
	vim.fn.setreg("+", abs_path)   -- Copy to system clipboard

	-- Only show notification if not called with ! (e.g., :CpAbsPath!)
	if not opts.bang then
		vim.notify("Copied ABSOLUTE path to clipboard:\n" .. abs_path, vim.log.levels.INFO)
	end
end, {
	bang = true, -- Allows :CpAbsPath! (silent mode)
	desc = "Copy absolute file path to clipboard",
})

vim.api.nvim_create_user_command("CpRelPath", function(opts)
	local file = vim.fn.expand("%")
	if file == "" then
		vim.notify("No file name detected (unsaved buffer?)", vim.log.levels.ERROR)
		return
	end

	local rel_path = vim.fn.expand("%:.") -- Path relative to working directory
	vim.fn.setreg("+", rel_path)   -- Copy to system clipboard

	-- Only show notification if not called with ! (e.g., :CpRelPath!)
	if not opts.bang then
		vim.notify("Copied RELATIVE path to clipboard:\n" .. rel_path, vim.log.levels.INFO)
	end
end, {
	bang = true, -- Allows :CpRelPath! (silent mode)
	desc = "Copy relative file path to clipboard",
})
