-- :DiffPR [--fetch] [number | url]
-- Opens the open GitHub PR for the current branch (or the PR given by number or URL)
-- in diffview, as `origin/<base>...<head>`: the three-dot range is the PR's own
-- layer, so a stacked PR shows only what it adds on top of its parent.
local M = {}

local PR_FIELDS = "number,state,title,baseRefName,headRefName,headRefOid,isCrossRepository"

-- Everything this module asks of GitHub or git, kept for the rest of the Neovim
-- session so a repeat `:DiffPR` opens without waiting: the gh lookups, the base
-- fetch, and the commit a PR's head was fetched to. Keys start with the repository,
-- so changing repo never reuses another repo's answers. `--fetch` ignores the cache
-- and replaces it. Only successes are cached.
local cache = {}

local function fail(msg)
	vim.notify("DiffPR: " .. msg, vim.log.levels.ERROR)
end

-- Runs cmd without blocking the UI; cb(ok, stdout, stderr) runs on the main loop.
local function run(cmd, cb)
	vim.system(cmd, { text = true }, function(res)
		vim.schedule(function()
			cb(res.code == 0, vim.trim(res.stdout or ""), vim.trim(res.stderr or ""))
		end)
	end)
end

-- Runs work(done) once per session per key. done(ok, value) stores a success and
-- calls cb(ok, value, from_cache), with value the result on success and the error on failure.
local function once(key, force, work, cb)
	local hit = cache[key]
	if hit ~= nil and not force then
		return vim.schedule(function()
			cb(true, hit, true)
		end)
	end
	work(function(ok, value)
		if ok then
			cache[key] = value
		end
		cb(ok, value, false)
	end)
end

-- A gh command, decoded from JSON.
local function gh(key, cmd, force, cb)
	once(key, force, function(done)
		run(cmd, function(ok, out, err)
			if not ok then
				return done(false, err)
			end
			done(true, vim.json.decode(out))
		end)
	end, cb)
end

-- Fetch what the diff needs and open it. The base is fetched into origin/<base>, which
-- stays put for the session. A PR's head is fetched from refs/pull/<n>/head and the
-- commit recorded, because FETCH_HEAD is overwritten by the next fetch. A local branch
-- checked out for its PR uses HEAD and needs no fetch of its own.
local function open_range(pr, branch, repo, force, from_cache)
	once(repo .. "|base|" .. pr.baseRefName, force, function(done)
		run({ "git", "fetch", "--quiet", "origin", pr.baseRefName }, function(ok, _, err)
			done(ok, ok and true or err)
		end)
	end, function(ok, err)
		if not ok then
			return fail("could not fetch origin/" .. pr.baseRefName .. ", not opening the diff\n" .. err)
		end

		local local_head = branch == pr.headRefName and not pr.isCrossRepository
		if not local_head then
			return once(repo .. "|head|" .. pr.number, force, function(done)
				run({ "git", "fetch", "--quiet", "origin", "refs/pull/" .. pr.number .. "/head" }, function(fetched, _, ferr)
					if not fetched then
						return done(false, ferr)
					end
					run({ "git", "rev-parse", "FETCH_HEAD" }, function(resolved, sha, rerr)
						done(resolved, resolved and sha or rerr)
					end)
				end)
			end, function(fetched, sha)
				if not fetched then
					return fail("could not fetch PR #" .. pr.number .. "'s head, not opening the diff\n" .. sha)
				end
				vim.cmd("DiffviewOpen origin/" .. pr.baseRefName .. "..." .. sha)
			end)
		end

		run({ "git", "rev-parse", "HEAD" }, function(_, head)
			if head ~= pr.headRefOid then
				local hint = from_cache and " PR data is cached for this session: `:DiffPR --fetch` refreshes it." or ""
				vim.notify(
					("DiffPR: your HEAD (%s) is not the PR's head (%s). The diff shows your local branch, not the PR as it is on GitHub. Push or pull first.%s"):format(
						head:sub(1, 7),
						pr.headRefOid:sub(1, 7),
						hint
					),
					vim.log.levels.WARN
				)
			end
			vim.cmd("DiffviewOpen origin/" .. pr.baseRefName .. "...HEAD")
		end)
	end)
end

local function pick(prs, branch, cb)
	if #prs == 1 then
		return cb(prs[1])
	end
	vim.ui.select(prs, {
		prompt = "Open PRs for " .. branch .. ":",
		format_item = function(pr)
			return ("#%d %s (into %s)"):format(pr.number, pr.title, pr.baseRefName)
		end,
	}, function(choice)
		if choice then
			cb(choice)
		end
	end)
end

function M.open(number, force)
	-- One git call for both: the branch, and the repository it belongs to.
	run({ "git", "rev-parse", "--abbrev-ref", "HEAD", "--show-toplevel" }, function(ok, out, err)
		if not ok then
			return fail("not in a git repository: " .. err)
		end
		local lines = vim.split(out, "\n")
		local branch, repo = lines[1], lines[2]
		if branch == "HEAD" then
			return fail("detached HEAD, check out the branch whose PR you want")
		end

		if number then
			return gh(repo .. "|pr|" .. number, { "gh", "pr", "view", tostring(number), "--json", PR_FIELDS }, force, function(gh_ok, pr, from_cache)
				if not gh_ok then
					return fail("no PR #" .. number .. ": " .. pr)
				end
				if pr.state ~= "OPEN" then
					return fail("PR #" .. number .. " is " .. pr.state:lower() .. ", only open PRs can be diffed")
				end
				open_range(pr, branch, repo, force, from_cache)
			end)
		end

		gh(
			repo .. "|branch|" .. branch,
			{ "gh", "pr", "list", "--head", branch, "--state", "open", "--limit", "20", "--json", PR_FIELDS },
			force,
			function(gh_ok, prs, from_cache)
				if not gh_ok then
					return fail("gh failed: " .. prs)
				end
				if #prs == 0 then
					return fail("no open PR for branch " .. branch)
				end
				pick(prs, branch, function(pr)
					open_range(pr, branch, repo, force, from_cache)
				end)
			end
		)
	end)
end

-- Turns the argument into a PR number. Accepts a bare number, or a GitHub PR URL
-- whose number is the segment after `pull`: the last element of a plain
-- .../pull/37, and still 37 with a trailing /files or ?query. A URL for another
-- repository is refused, since its number would be looked up in this one.
local function parse_target(arg)
	local number = arg:match("^%d+$")
	if number then
		return tonumber(number)
	end

	local owner, repo, pr_number = arg:match("^https?://[^/]+/([^/]+)/([^/]+)/pull/(%d+)")
	if not pr_number then
		return nil, "expected a PR number or a GitHub PR URL, got '" .. arg .. "'"
	end

	local remote = vim.trim(vim.system({ "git", "remote", "get-url", "origin" }, { text = true }):wait().stdout or "")
	local origin_owner, origin_repo = remote:match("[:/]([^/:]+)/([^/]+)$")
	origin_repo = origin_repo and origin_repo:gsub("%.git$", "")
	if not origin_owner or origin_owner:lower() ~= owner:lower() or origin_repo:lower() ~= repo:lower() then
		return nil, ("PR URL is for %s/%s, but origin is %s/%s"):format(owner, repo, origin_owner or "?", origin_repo or "?")
	end

	return tonumber(pr_number)
end

vim.api.nvim_create_user_command("DiffPR", function(opts)
	local force, target = false, nil
	for _, arg in ipairs(opts.fargs) do
		if arg == "--fetch" then
			force = true
		elseif arg:sub(1, 1) == "-" then
			return fail("unknown option '" .. arg .. "'")
		elseif target then
			return fail("expected one PR number or URL")
		else
			target = arg
		end
	end

	local number
	if target then
		local err
		number, err = parse_target(target)
		if not number then
			return fail(err)
		end
	end
	M.open(number, force)
end, { nargs = "*", desc = "Diff a GitHub PR (number or URL), or the open PR for this branch, in diffview. --fetch refetches everything." })

return M
