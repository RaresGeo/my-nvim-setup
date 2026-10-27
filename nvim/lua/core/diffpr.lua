-- :DiffPR [number]
-- Opens the open GitHub PR for the current branch (or the PR given by number)
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

vim.api.nvim_create_user_command("DiffPR", function(opts)
	local number
	if opts.args ~= "" then
		number = tonumber(opts.args)
		if not number then
			return fail("expected a PR number, got '" .. opts.args .. "'")
		end
	end
	M.open(number)
end, { nargs = "?", desc = "Diff the open GitHub PR for this branch (or PR number) in diffview" })

return M
