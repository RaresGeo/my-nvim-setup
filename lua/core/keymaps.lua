-- General keymaps
vim.keymap.set("n", "<leader>f", function()
	vim.lsp.buf.format()
end, { desc = "Format buffer" })

vim.keymap.set("n", ",m", function()
	vim.cmd(":%s/\r//g")
end, { desc = "Clear ^M from pasting from Windows" })

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
