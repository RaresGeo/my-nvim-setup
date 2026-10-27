# Neovim Configuration

My neovim configuration, for a balance of productivity and raw programming.
While using VSCode, I noticed I had gotten used to too many crutches, so I decided to switch to something faster, but I also didn't want to completely cripple myself.
This, I find, strikes a good balance.

## Installation

This directory is one module of the [dotfiles repo](../README.md) it lives in.
Install it by symlinking the directory into place and bootstrapping plugins:

```bash
../install.sh nvim         # or ./install.sh nvim from the repo root
```

That links this directory to `~/.config/nvim` and runs `:Lazy restore` headless
against the checked-in `lazy-lock.json`. Pass `--no-plugins` to skip the plugin
bootstrap, or `--no-packages` to skip installing neovim and its CLI dependencies.

## Dependencies

Off the top of my head, below are listed some of the dependencies you will need to run this configuration.

### Required

- **Neovim** >= 0.9.0
- **Git**
- **Node.js** and **npm** (for TypeScript/JavaScript LSP, I personally use `volta` for this)
- **ripgrep** (`rg`) - Fast file searching for Telescope and ignoring .gitignored files
- **coursier** (`cs`) - Scala artifact fetching, you will use this to install metals
- **sbt** - simple build tool for scala projects
- **Deno** - If working with Deno projects

### Optional

- **GitHub CLI** (`gh`), logged in with `gh auth login` - needed by `:Octo` for pull request review (octo.nvim). Nothing else uses it.

I installed most of these using `homebrew`

## Plugin Manager

This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. It will automatically bootstrap itself on first run.
After each update, it will open a floating window with some commands. You can focus it with your mouse (or probably with C-w also) then use `:q` to close it

## Key Features

### 🔍 **File Navigation**

- **Telescope** for fuzzy finding files, buffers, and live grep
- **Oil.nvim** for file exploration
- **Harpoon** for quick file switching
- Custom recent files picker (I wanted to mimick the functionality of ctrl + tab in VSCode)
- Toggle between most recent file and most recent terminal `(<Space>\`)`

### 💻 **Language Support**

- **TypeScript/JavaScript** (ts_ls)
- **Scala** (Metals)
- **Lua** (lua_ls)
- **Deno** support
- **Go** support (gopls)
- Auto-completion with **blink.cmp** and **emmet-ls**
- Auto-pairs with **nvim-autopairs**

### 🔀 **Git & Code Review**

- **diffview.nvim** for side-by-side diffs and file history
- **git-conflict.nvim** for resolving merge conflicts
- **octo.nvim** for reviewing GitHub pull requests in Neovim: the changed-files panel, viewed marks, inline comments and review submission

### ✨ **Developer Experience**

- Auto-formatting on save
- Intelligent commenting via Neovim's built-in commenting with context awareness (also works in jsx/tsx)
- Snippet support
- LSP-powered code navigation and actions
- Git blame

## Important Keymaps

### Leader Key

- Leader key is set to `<Space>`

### File Navigation

| Keymap                     | Action                   |
| -------------------------- | ------------------------ |
| `<leader>e`                | Open file explorer (Oil) |
| `<leader>ff`               | Find files (Telescope)   |
| `<leader>fg`               | Live grep (Telescope)    |
| `<leader>fb`               | Find buffers (Telescope) |
| `<leader>fh`               | Help tags (Telescope)    |
| `<leader><Tab>` | Recent files picker      |

### Harpoon (Quick File Switching)

| Keymap      | Action                |
| ----------- | --------------------- |
| `<leader>a` | Add file to harpoon   |
| `<C-e>`     | Open harpoon window   |
| `<C-S-P>`   | Previous harpoon file |
| `<C-S-N>`   | Next harpoon file     |

### LSP & Code Navigation

| Keymap       | Action                 |
| ------------ | ---------------------- |
| `gd`         | Go to definition       |
| `gD`         | Go to declaration      |
| `gi`         | Go to implementation   |
| `gr`         | Go to references       |
| `K`          | Show hover information |
| `<leader>ca` | Code actions           |
| `<leader>rn` | Rename symbol          |
| `<leader>f`  | Format buffer          |

### Diagnostics

| Keymap      | Action                           |
| ----------- | -------------------------------- |
| `]d`        | Next diagnostic                  |
| `[d`        | Previous diagnostic              |
| `<leader>d` | Open diagnostic float            |
| `<leader>q` | Add diagnostics to location list |

### Commenting

| Keymap  | Action                            |
| ------- | --------------------------------- |
| `<C-/>` | Toggle line comment               |
| `gcc`   | Toggle line comment (normal mode) |
| `gc`    | Toggle comment (visual mode)      |
| `gbc`   | Toggle block comment              |

### Metals (Scala) Specific

| Keymap       | Action                    |
| ------------ | ------------------------- |
| `<leader>mt` | Toggle Metals tree view   |
| `<leader>mr` | Reveal in Metals tree     |
| `<leader>mw` | Metals worksheet commands |

### Git

| Keymap              | Action                                   |
| ------------------- | ---------------------------------------- |
| `<leader>dv`        | Diff view of unstaged changes (Diffview) |
| `<leader>dh`        | File history of current file (Diffview)  |
| `<leader>dq`        | Close diff view                          |
| `]x` / `[x`         | Next / previous conflict                 |
| `<leader>gco`       | Choose ours (current branch)             |
| `<leader>gct`       | Choose theirs (incoming branch)          |
| `<leader>gcb`       | Choose both                              |
| `<leader>gc0`       | Choose none                              |
| `<leader>gcl`       | List conflicts (Telescope)               |

### Pull Requests (octo.nvim)

Octo commands, run from inside Neovim. Pick a PR from the list, or let it find
the one for the branch you are on.

| Command                | Action                                 |
| ---------------------- | -------------------------------------- |
| `:Octo pr list`        | Browse open pull requests (Telescope)  |
| `:Octo <PR URL>`       | Open a pull request by URL             |
| `:Octo review start`   | Start a review of the current PR       |
| `:Octo review resume`  | Resume a pending review                |
| `:Octo review submit`  | Submit the pending review              |
| `:Octo review discard` | Discard the pending review             |

Inside a review tab:

| Keymap                   | Action                              |
| ------------------------ | ----------------------------------- |
| `]q` / `[q`             | Next / previous changed file        |
| `]u` / `[u`             | Next / previous unviewed file       |
| `<localleader><Space>`   | Toggle the viewed state of the file |
| `<localleader>e`         | Move focus to the file panel        |
| `<localleader>b`         | Hide / show the file panel          |
| `<localleader>ca`        | Add a review comment                |
| `<localleader>vs`        | Submit the review                   |
| `<localleader>vd`        | Discard the review                  |
| `<C-c>`                  | Close the review tab                |

`<localleader>` is `\`. Octo's buffer mappings are local to its own buffers,
so they do not change `]q`, `[q` or the rest elsewhere.

## Plugin List

### Core Functionality

- **lazy.nvim** - Plugin manager
- **plenary.nvim** - Lua utility functions

### UI & Themes

- **catppuccin/nvim** - Colorscheme
- **Everforest** - Colorscheme
- **nvim-web-devicons** - File icons

### File Management

- **telescope.nvim** - Fuzzy finder and picker
- **oil.nvim** - File explorer
- **harpoon** - Quick file navigation

### Git & Code Review

- **diffview.nvim** - Diff view and file history
- **git-conflict.nvim** - Merge conflict resolution
- **octo.nvim** - GitHub pull requests and review

## Language Server Setup

### TypeScript/JavaScript

The `ts_ls` language server will be automatically installed when you first open a TS/JS file.
You must install deno, which can be done via a package manager. i.e. `npm install -g deno`

### Go

There are multiple ways of installing go, which will automatically come with `gopls`
See documentation for your preferred way https://go.dev/doc/install

### Scala (Metals)

Metals will prompt you to import your build when you first open a Scala project. Follow the prompts to set up your workspace.

### Lua

The `lua_ls` server is configured for Neovim configuration development with proper `vim` global recognition.

## Customization

This configuration is designed to be easily extensible. To add new plugins:

1. Create a new file in `lua/plugins/`
2. Return a plugin specification table
3. Restart Neovim or run `:Lazy sync`
