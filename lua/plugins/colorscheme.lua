-- The colorscheme is driven by omarchy: the active theme ships a lazy.nvim spec
-- at ~/.local/state/omarchy/current/theme/neovim.lua, which is re-pointed every
-- time the theme changes.
--
-- Since Omarchy 4 most themes are aether with a generated palette living in the
-- spec's `opts`, so applying a theme means running that plugin's setup() with
-- those opts -- reading a name and calling :colorscheme is no longer enough.

local theme_dir = vim.fn.expand("~/.local/state/omarchy/current/theme")
local theme_file = theme_dir .. "/neovim.lua"
local colors_file = theme_dir .. "/colors.toml"

-- Mirrors omarchy's own all-themes list, so whichever theme omarchy switches to
-- is already installed and can be applied without restarting nvim. Names and
-- branches have to match the generated theme specs or lazy resolves them to a
-- different directory than the one the spec asks for.
local theme_plugins = {
	{ "bjarneo/aether.nvim", branch = "v3", name = "aether", lazy = true, priority = 1000 },
	{ "bjarneo/ethereal.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/hackerman.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/vantablack.nvim", lazy = true, priority = 1000 },
	{ "bjarneo/white.nvim", lazy = true, priority = 1000 },
	{ "catppuccin/nvim", name = "catppuccin", lazy = true, priority = 1000 },
	{ "ellisonleao/gruvbox.nvim", lazy = true, priority = 1000 },
	{ "EdenEast/nightfox.nvim", lazy = true, priority = 1000 },
	{ "ficcdaf/ashen.nvim", lazy = true, priority = 1000 },
	{ "folke/tokyonight.nvim", lazy = true, priority = 1000 },
	{ "gthelding/monokai-pro.nvim", lazy = true, priority = 1000 },
	{ "kepano/flexoki-neovim", lazy = true, priority = 1000 },
	{ "neanias/everforest-nvim", lazy = true, priority = 1000 },
	{ "omacom-io/lumon.nvim", lazy = true, priority = 1000 },
	{ "OldJobobo/miasma.nvim", lazy = true, priority = 1000 },
	{ "OldJobobo/retro-82.nvim", lazy = true, priority = 1000 },
	{ "rebelot/kanagawa.nvim", lazy = true, priority = 1000 },
	{ "ribru17/bamboo.nvim", lazy = true, priority = 1000 },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true, priority = 1000 },
	{ "tahayvr/matteblack.nvim", lazy = true, priority = 1000 },
	-- Needed by the hand-written solarized-light theme in ~/.config/omarchy/themes
	{ "maxmx03/solarized.nvim", lazy = true, priority = 1000 },
}

-- Themes ship either a list of specs or, for hand-written ones, a single spec.
local function read_spec()
	if vim.fn.filereadable(theme_file) == 0 then
		return nil
	end
	local ok, spec = pcall(dofile, theme_file)
	if not ok or type(spec) ~= "table" then
		return nil
	end
	return type(spec[1]) == "string" and { spec } or spec
end

-- The colorscheme name rides on the LazyVim spec; the plugin to load, and the
-- opts carrying the palette, ride on the other one.
local function parse_spec(spec)
	local colorscheme, plugin
	for _, entry in ipairs(spec) do
		if type(entry) == "table" and type(entry[1]) == "string" then
			if entry[1] == "LazyVim/LazyVim" then
				colorscheme = entry.opts and entry.opts.colorscheme
			elseif not plugin then
				plugin = entry
			end
		end
	end
	return colorscheme, plugin
end

local function plugin_name(plugin)
	return plugin.name or plugin[1]:match("([^/]+)$")
end

local function module_name(plugin)
	return (plugin_name(plugin):gsub("%.nvim$", ""))
end

local function is_light()
	if vim.fn.filereadable(colors_file) == 1 then
		for _, line in ipairs(vim.fn.readfile(colors_file)) do
			local mode = line:match('^%s*mode%s*=%s*"([^"]+)"')
			if mode then
				return mode == "light"
			end
		end
	end
	return false
end

-- Two themes on the same plugin (the common case now that most are aether) hand
-- it a different palette, but its lua modules still hold the old one.
local function unload_plugin_modules(name)
	local plugin = require("lazy.core.config").plugins[name]
	if not plugin then
		return
	end
	pcall(require("lazy.core.util").walkmods, plugin.dir .. "/lua", function(modname)
		package.loaded[modname] = nil
		package.preload[modname] = nil
	end)
end

local applied = nil

local function apply_theme()
	local spec = read_spec()
	if not spec then
		return
	end

	local colorscheme, plugin = parse_spec(spec)
	if not plugin then
		return
	end

	-- The palette lives in opts, so the name alone can't tell us it changed.
	local fingerprint = vim.inspect({ colorscheme, plugin })
	if fingerprint == applied then
		return
	end

	local name = plugin_name(plugin)
	if not require("lazy.core.config").plugins[name] then
		return
	end

	vim.o.background = is_light() and "light" or "dark"

	if applied then
		vim.cmd("highlight clear")
		if vim.fn.exists("syntax_on") == 1 then
			vim.cmd("syntax reset")
		end
	end

	unload_plugin_modules(name)
	require("lazy").load({ plugins = { name } })

	if type(plugin.config) == "function" then
		-- Hand-written themes run their own setup and :colorscheme.
		if not pcall(plugin.config, plugin, plugin.opts or {}) then
			return
		end
	else
		if plugin.opts then
			local ok, mod = pcall(require, module_name(plugin))
			if ok and type(mod) == "table" and type(mod.setup) == "function" then
				pcall(mod.setup, plugin.opts)
			end
		end
		if not colorscheme or not pcall(vim.cmd.colorscheme, colorscheme) then
			return
		end
	end

	applied = fingerprint
end

vim.api.nvim_create_autocmd("VimEnter", {
	desc = "Apply omarchy colorscheme on startup",
	callback = apply_theme,
})

-- Hotswap on focus; the omarchy theme-set hook pokes running instances with a
-- synthetic FocusGained.
vim.api.nvim_create_autocmd("FocusGained", {
	desc = "Hotswap omarchy colorscheme on focus",
	callback = apply_theme,
})

return theme_plugins
