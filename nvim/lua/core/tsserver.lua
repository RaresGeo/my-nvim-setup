-- typescript-language-server bundles no compiler: it drives TypeScript's own
-- tsserver.js and only looks for it under the LSP root. Homebrew's `typescript`
-- is the native 7.x port now, which ships no tsserver.js at all, so the bundled
-- fallback is a dead end and the server exits on startup. Resolve it here
-- instead: walk up from the root so a pnpm workspace that does not depend on
-- typescript itself still finds the copy at the repo root.
local M = {}

local uv = vim.uv or vim.loop

local relative_candidates = {
    "node_modules/typescript/lib/tsserver.js",
    -- pnpm only links typescript into a workspace that depends on it directly;
    -- this hidden directory has it whenever anything in the repo does.
    "node_modules/.pnpm/node_modules/typescript/lib/tsserver.js",
    ".yarn/sdks/typescript/lib/tsserver.js",
    ".vscode/pnpify/typescript/lib/tsserver.js",
}

-- Installed by nvim/install.sh; the last TypeScript line that ships tsserver.js.
M.fallback = vim.fs.joinpath(vim.fn.stdpath("data"), "tsserver", "node_modules", "typescript", "lib", "tsserver.js")

local function is_file(path)
    local stat = uv.fs_stat(path)
    return stat ~= nil and stat.type == "file"
end

-- Nearest tsserver.js at or above start_dir, else the pinned fallback, else nil.
function M.resolve(start_dir)
    if start_dir and start_dir ~= "" then
        local dirs = { start_dir }
        for parent in vim.fs.parents(start_dir) do
            dirs[#dirs + 1] = parent
        end

        for _, dir in ipairs(dirs) do
            for _, candidate in ipairs(relative_candidates) do
                local path = vim.fs.joinpath(dir, candidate)
                if is_file(path) then
                    return path
                end
            end
        end
    end

    if is_file(M.fallback) then
        return M.fallback
    end
    return nil
end

-- nvim fills initializationOptions in before before_init runs, so the resolved
-- path has to go onto the params rather than onto the config table.
function M.before_init(params, config)
    local root = config.root_dir or params.rootPath
    local path = M.resolve(root)
    if not path then
        vim.schedule(function()
            vim.notify(
                "No tsserver.js found for " .. tostring(root) .. "; run nvim/install.sh to install the fallback TypeScript.",
                vim.log.levels.WARN
            )
        end)
        return
    end
    params.initializationOptions = vim.tbl_deep_extend("force", params.initializationOptions or {}, {
        tsserver = { path = path },
    })
end

return M
