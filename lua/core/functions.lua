_G.open_terminal_in_current_dir = function()
	local current_file = vim.fn.expand("%:p")
	local dir
	if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
		-- Get directory of current file
		dir = vim.fn.fnamemodify(current_file, ":h")
	else
		-- Fallback to current working directory
		dir = vim.fn.getcwd()
	end
	vim.cmd("terminal")
	-- Change to the directory in the terminal
	vim.fn.chansend(vim.b.terminal_job_id, "export NVIM_TERMINAL=1\r")
	vim.fn.chansend(vim.b.terminal_job_id, "cd " .. vim.fn.shellescape(dir) .. "\r")
	-- Change back to the base directory.
	-- I found that opening a terminal in the actual current directory is rarely desired
	-- But this allows me to just use `cd -` again if I really did want it
	vim.fn.chansend(vim.b.terminal_job_id, "cd - \r")
	vim.cmd("startinsert")
end
