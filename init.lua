-- Set leader key
vim.g.mapleader = " "

-- Load plugin manager
require("config.lazy")

-- Load configuration modules
require("core.options")
require("core.keymaps")
require("core.autocmds")
