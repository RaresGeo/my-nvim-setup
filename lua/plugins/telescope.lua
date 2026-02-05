vim.api.nvim_create_user_command("List", function(opts)
    local arg = opts.args:lower()
    local symbols_filter = nil

    if arg == "functions" then
        symbols_filter = { "function" }
    elseif arg == "methods" then
        symbols_filter = { "method" }
    elseif arg == "classes" then
        symbols_filter = { "class", "interface" }
    elseif arg == "variables" then
        symbols_filter = { "variable", "constant" }
    elseif arg == "types" then
        symbols_filter = { "class", "interface", "enum", "struct" }
    elseif arg ~= "all" then
        -- Handle comma-separated combinations like 'functions,methods'
        local parts = vim.split(arg, ",")
        symbols_filter = {}
        for _, part in ipairs(parts) do
            part = vim.trim(part)
            if part == "functions" then
                table.insert(symbols_filter, "function")
            elseif part == "methods" then
                table.insert(symbols_filter, "method")
                -- Add other mappings as needed
            end
        end
    end

    require("telescope.builtin").lsp_document_symbols({
        symbols = symbols_filter,
    })
end, {
    nargs = 1,
    complete = function()
        return { "all", "functions", "methods", "classes", "variables", "types" }
    end,
})

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
                    "--hidden",       -- Include hidden files
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
                        "--hidden",       -- Include hidden files
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
                    default_selection_index = 2,         -- Start with second entry selected
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

        local terminal_buf = nil -- Track the terminal buffer
        local terminal_win = nil -- Track the terminal window

        local function toggle_terminal_split()
            print("Toggling terminal split")

            -- Check if terminal window exists and is visible
            if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
                -- Hide the terminal split
                vim.api.nvim_win_close(terminal_win, false)
                terminal_win = nil
                return
            end

            -- Terminal window doesn't exist or is closed, but buffer might exist
            local current_file = vim.fn.expand("%:p")
            local dir
            if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
                dir = vim.fn.fnamemodify(current_file, ":h")
            else
                dir = vim.fn.getcwd()
            end

            -- Create horizontal split at the bottom
            vim.cmd("botright split")
            vim.cmd("resize 20")

            -- Check if we have an existing terminal buffer
            if terminal_buf and vim.api.nvim_buf_is_loaded(terminal_buf) then
                -- Reuse existing terminal buffer
                vim.cmd("buffer " .. terminal_buf)
            else
                -- Create new terminal
                vim.cmd("terminal")
                terminal_buf = vim.api.nvim_get_current_buf()

                -- Only setup the terminal if it's new
                vim.fn.chansend(vim.b.terminal_job_id, "export NVIM_TERMINAL=1\r")
                vim.fn.chansend(vim.b.terminal_job_id, "cd " .. vim.fn.shellescape(dir) .. "\r")
                vim.fn.chansend(vim.b.terminal_job_id, "cd - \r")
                vim.fn.chansend(vim.b.terminal_job_id, "clear \r")
            end

            -- Store the window ID
            terminal_win = vim.api.nvim_get_current_win()

            vim.cmd("startinsert")
        end

        -- Make functions available globally
        _G.RecentFiles = {
            show_picker = show_recent_files_picker,
            add_file = add_recent_file,
            toggle_terminal_split = toggle_terminal_split,
            get_recent = function()
                return recent_files
            end,
            clear = function()
                recent_files = {}
            end,
        }

        -- Key mappings
        vim.keymap.set("n", "<leader>tr", "<cmd>Telescope resume<cr>")
        vim.keymap.set("n", "<C-;>", show_recent_files_picker, { desc = "Show recent files picker" })
        vim.keymap.set("n", "<leader><Tab>", show_recent_files_picker, { desc = "Show recent files picker" })
        vim.keymap.set("n", "<M-`>", toggle_terminal_split,
            { desc = "Toggle between recent terminal and file" })
        vim.keymap.set("t", "<M-`>", function()
            -- Exit terminal mode first, then call the function
            vim.cmd("stopinsert")
            toggle_terminal_split()
        end, { desc = "Toggle between recent terminal and file" })
    end,
}
