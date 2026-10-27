-- :DiffPR [number | url]
-- Opens the open GitHub PR for the current branch (or the PR given by number or URL)
-- in diffview, as `origin/<base>...<head>`: the three-dot range is the PR's own
-- layer, so a stacked PR shows only what it adds on top of its parent.
local M = {}

local PR_FIELDS = "number,state,title,baseRefName,headRefName,headRefOid,isCrossRepository"

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

-- Fetch what the diff needs and open it: `base` always from origin, and the
-- PR's head from refs/pull/<n>/head unless it is the local branch checked out.
local function open_range(pr, branch)
	run({ "git", "fetch", "--quiet", "origin", pr.baseRefName }, function(ok, _, err)
		if not ok then
			return fail("could not fetch origin/" .. pr.baseRefName .. ", not opening the diff\n" .. err)
		end

		local local_head = branch == pr.headRefName and not pr.isCrossRepository
		if not local_head then
			return run({ "git", "fetch", "--quiet", "origin", "refs/pull/" .. pr.number .. "/head" }, function(fetched, _, ferr)
				if not fetched then
					return fail("could not fetch PR #" .. pr.number .. "'s head, not opening the diff\n" .. ferr)
				end
				vim.cmd("DiffviewOpen origin/" .. pr.baseRefName .. "...FETCH_HEAD")
			end)
		end

		run({ "git", "rev-parse", "HEAD" }, function(_, head)
			if head ~= pr.headRefOid then
				vim.notify(
					("DiffPR: your HEAD (%s) is not the PR's head (%s). The diff shows your local branch, not the PR as it is on GitHub. Push or pull first."):format(
						head:sub(1, 7),
						pr.headRefOid:sub(1, 7)
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

function M.open(number)
	run({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, function(ok, branch, err)
		if not ok then
			return fail("not in a git repository: " .. err)
		end
		if branch == "HEAD" then
			return fail("detached HEAD, check out the branch whose PR you want")
		end

		if number then
			return run({ "gh", "pr", "view", tostring(number), "--json", PR_FIELDS }, function(gh_ok, out, gh_err)
				if not gh_ok then
					return fail("no PR #" .. number .. ": " .. gh_err)
				end
				local pr = vim.json.decode(out)
				if pr.state ~= "OPEN" then
					return fail("PR #" .. number .. " is " .. pr.state:lower() .. ", only open PRs can be diffed")
				end
				open_range(pr, branch)
			end)
		end

		run(
			{ "gh", "pr", "list", "--head", branch, "--state", "open", "--limit", "20", "--json", PR_FIELDS },
			function(gh_ok, out, gh_err)
				if not gh_ok then
					return fail("gh failed: " .. gh_err)
				end
				local prs = vim.json.decode(out)
				if #prs == 0 then
					return fail("no open PR for branch " .. branch)
				end
				pick(prs, branch, function(pr)
					open_range(pr, branch)
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
	local number, err
	if opts.args ~= "" then
		number, err = parse_target(opts.args)
		if not number then
			return fail(err)
		end
	end
	M.open(number)
end, { nargs = "?", desc = "Diff a GitHub PR (number or URL), or the open PR for this branch, in diffview" })

return M
