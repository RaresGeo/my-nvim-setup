-- oxfmt is a project's own formatter, pinned in its lockfile, so the binary has
-- to come from the project rather than from PATH. Walk up for it the way
-- core/tsserver walks up for the compiler: a monorepo declares it once at the
-- root, and pnpm links a direct dependency's bin into node_modules/.bin there
-- rather than into each workspace that uses it.
local M = {}

local uv = vim.uv or vim.loop

local function is_executable(path)
    local stat = uv.fs_stat(path)
    return stat ~= nil and stat.type == "file" and vim.fn.executable(path) == 1
end

-- Nearest project-local oxfmt at or above start_dir, else nil. Deliberately no
-- PATH fallback: formatting to a version the project did not pin would move the
-- editor/repo disagreement rather than end it.
function M.resolve(start_dir)
    if not start_dir or start_dir == "" then
        return nil
    end

    local dirs = { start_dir }
    for parent in vim.fs.parents(start_dir) do
        dirs[#dirs + 1] = parent
    end

    for _, dir in ipairs(dirs) do
        local path = vim.fs.joinpath(dir, "node_modules/.bin/oxfmt")
        if is_executable(path) then
            return path
        end
    end
    return nil
end

return M
