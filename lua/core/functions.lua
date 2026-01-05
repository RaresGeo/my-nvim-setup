local function open_terminal_in_current_dir()
	local current_file = vim.fn.expand("%:p")
	local dir
	if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
		-- Get directory of current file
		dir = vim.fn.fnamemodify(current_file, ":h")
	else
		-- Fallback to current working directory
		dir = vim.fn.getcwd()
	end

	-- Count existing terminal tabs
	local terminal_count = 0
	for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
		local buflist = vim.api.nvim_tabpage_list_wins(tabnr)
		for _, winid in ipairs(buflist) do
			local bufnr = vim.api.nvim_win_get_buf(winid)
			if vim.api.nvim_buf_get_name(bufnr):match("Terminal") then
				terminal_count = terminal_count + 1
				break
			end
		end
	end

	-- Create a new tab
	vim.cmd("tabnew")

	-- Open terminal in this tab
	vim.cmd("terminal")

	-- Rename the tab
	vim.cmd("file Terminal " .. (terminal_count + 1))

	-- Change to the directory in the terminal
	vim.fn.chansend(vim.b.terminal_job_id, "export NVIM_TERMINAL=1\r")
	vim.fn.chansend(vim.b.terminal_job_id, "cd " .. vim.fn.shellescape(dir) .. "\r")
	-- Change back to the base directory.
	-- I found that opening a terminal in the actual current directory is rarely desired
	-- But this allows me to just use `cd -` again if I really did want it
	vim.fn.chansend(vim.b.terminal_job_id, "cd - \r")
	vim.fn.chansend(vim.b.terminal_job_id, "clear \r")
	vim.cmd("startinsert")
end

local function escape_wildcards(path)
  return path:gsub('([%[%]%?%*])', '\\%1')
end

-- For zipfile: or tarfile: virtual paths, returns the path to the archive.
-- Other paths are returned unaltered.
local function strip_archive_subpath(path)
  -- Matches regex from zip.vim / tar.vim
  path = vim.fn.substitute(path, 'zipfile://\\(.\\{-}\\)::[^\\\\].*$', '\\1', '')
  path = vim.fn.substitute(path, 'tarfile:\\(.\\{-}\\)::.*$', '\\1', '')
  return path
end

local function search_ancestors(startpath, func)
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in vim.fs.parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

local function tbl_flatten(t)
  if vim.fn.has('nvim-0.11') == 1 then
    return vim.iter(t):flatten(math.huge):totable()
  else
    return vim.tbl_flatten(t)
  end
end

--- Returns a function which matches a filepath against the given glob/wildcard patterns.
---
--- Also works with zipfile:/tarfile: buffers (via `strip_archive_subpath`).
local function root_pattern(...)
  local patterns = tbl_flatten { ... }
  return function(startpath)
    startpath = strip_archive_subpath(startpath)
    for _, pattern in ipairs(patterns) do
      local match = search_ancestors(startpath, function(path)
        for _, p in ipairs(vim.fn.glob(table.concat({ escape_wildcards(path), pattern }, '/'), true, true)) do
          if vim.uv.fs_stat(p) then
            return path
          end
        end
      end)

      if match ~= nil then
        local real = vim.uv.fs_realpath(match)
        return real or match -- fallback to original if realpath fails
      end
    end
  end
end


_G.open_terminal_in_current_dir = open_terminal_in_current_dir
_G.root_pattern = root_pattern
