-- All colorscheme plugins that omarchy themes may use.
-- The active colorscheme is read from omarchy at startup and on FocusGained.

-- Map from colorscheme name -> lazy.nvim plugin name for loading
local colorscheme_to_plugin = {
    ["catppuccin"] = "catppuccin",
    ["catppuccin-latte"] = "catppuccin",
    ["catppuccin-mocha"] = "catppuccin",
    ["catppuccin-frappe"] = "catppuccin",
    ["catppuccin-macchiato"] = "catppuccin",
    ["ethereal"] = "ethereal.nvim",
    ["everforest"] = "everforest-nvim",
    ["flexoki"] = "flexoki-neovim",
    ["flexoki-light"] = "flexoki-neovim",
    ["flexoki-dark"] = "flexoki-neovim",
    ["gruvbox"] = "gruvbox.nvim",
    ["hackerman"] = "hackerman.nvim",
    ["kanagawa"] = "kanagawa.nvim",
    ["kanagawa-wave"] = "kanagawa.nvim",
    ["kanagawa-dragon"] = "kanagawa.nvim",
    ["kanagawa-lotus"] = "kanagawa.nvim",
    ["matteblack"] = "matteblack.nvim",
    ["miasma"] = "miasma.nvim",
    ["nordfox"] = "nightfox.nvim",
    ["bamboo"] = "bamboo.nvim",
    ["monokai-pro"] = "monokai-pro.nvim",
    ["rose-pine"] = "rose-pine",
    ["rose-pine-dawn"] = "rose-pine",
    ["rose-pine-moon"] = "rose-pine",
    ["rose-pine-main"] = "rose-pine",
    ["tokyonight"] = "tokyonight.nvim",
    ["tokyonight-night"] = "tokyonight.nvim",
    ["tokyonight-storm"] = "tokyonight.nvim",
    ["tokyonight-day"] = "tokyonight.nvim",
    ["tokyonight-moon"] = "tokyonight.nvim",
    ["vantablack"] = "vantablack.nvim",
    ["white"] = "white.nvim",
}

local theme_plugins = {
    { "catppuccin/nvim", name = "catppuccin", lazy = true },
    { "bjarneo/ethereal.nvim", lazy = true },
    { "neanias/everforest-nvim", name = "everforest-nvim", lazy = true },
    { "kepano/flexoki-neovim", lazy = true },
    { "ellisonleao/gruvbox.nvim", lazy = true },
    { "bjarneo/aether.nvim", lazy = true },
    { "bjarneo/hackerman.nvim", lazy = true },
    { "rebelot/kanagawa.nvim", lazy = true },
    { "tahayvr/matteblack.nvim", lazy = true },
    { "xero/miasma.nvim", lazy = true },
    { "EdenEast/nightfox.nvim", lazy = true },
    { "ribru17/bamboo.nvim", lazy = true },
    {
        "gthelding/monokai-pro.nvim",
        lazy = true,
        config = function()
            require("monokai-pro").setup({ filter = "ristretto" })
        end,
    },
    { "rose-pine/neovim", name = "rose-pine", lazy = true },
    { "folke/tokyonight.nvim", lazy = true },
    { "bjarneo/vantablack.nvim", lazy = true },
    { "bjarneo/white.nvim", lazy = true },
    { "sainnhe/everforest", lazy = true },
}

local omarchy_theme_dir = vim.fn.expand("~/.config/omarchy/current/theme")
local omarchy_theme_file = omarchy_theme_dir .. "/neovim.lua"
local last_colorscheme = nil

local function get_omarchy_colorscheme()
    if vim.fn.filereadable(omarchy_theme_file) == 0 then
        return nil
    end
    local lines = vim.fn.readfile(omarchy_theme_file)
    local text = table.concat(lines, "\n")
    return text:match('colorscheme%s*=%s*"([^"]+)"')
end

local function is_light_theme()
    return vim.fn.filereadable(omarchy_theme_dir .. "/light.mode") == 1
end

local function apply_omarchy_theme()
    local cs = get_omarchy_colorscheme()
    if cs and cs ~= last_colorscheme then
        -- Set background before loading the colorscheme so it picks the right variant
        vim.o.background = is_light_theme() and "light" or "dark"
        -- Load the plugin first if we know which one provides this colorscheme
        local plugin_name = colorscheme_to_plugin[cs]
        if plugin_name then
            require("lazy").load({ plugins = { plugin_name } })
        end
        local ok = pcall(vim.cmd.colorscheme, cs)
        if ok then
            last_colorscheme = cs
        end
    end
end

-- Apply on startup (after plugins are loaded)
vim.api.nvim_create_autocmd("VimEnter", {
    desc = "Apply omarchy colorscheme on startup",
    callback = apply_omarchy_theme,
})

-- Hotswap on focus (when switching back from theme picker)
vim.api.nvim_create_autocmd("FocusGained", {
    desc = "Hotswap omarchy colorscheme on focus",
    callback = apply_omarchy_theme,
})

return theme_plugins
