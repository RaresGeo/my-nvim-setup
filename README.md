# Neovim Configuration

My neovim configuration, for a balance of productivity and raw programming.
While using VSCode, I noticed I had gotten used to too many crutches, so I decided to switch to something faster, but I also didn't want to completely cripple myself.
This, I find, strikes a good balance.

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

I installed most of these using `homebrew`

## Plugin Manager

This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. It will automatically bootstrap itself on first run.
After each update, it will open a floating window with some commands. You can focus it with your mouse (or probably with C-w also) then use `:q` to close it

## Key Features

### 🎨 **Appearance**

- **Catppuccin** and **Everforest** colorscheme
- **Treesitter** syntax highlighting

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

### ✨ **Developer Experience**

- Auto-formatting on save
- Intelligent commenting with context awareness (also works in jsx/tsx)
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
| `<C-;>` or `<leader><Tab>` | Recent files picker      |

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

### Metals (Scala) Specific

| Keymap       | Action                    |
| ------------ | ------------------------- |
| `<leader>mt` | Toggle Metals tree view   |
| `<leader>mr` | Reveal in Metals tree     |
| `<leader>mw` | Metals worksheet commands |

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

### Language Support

- **nvim-lspconfig** - LSP configurations
- **nvim-treesitter** - Syntax highlighting
- **blink-cmp** - Auto-completion engine
- **LuaSnip** - Snippet engine


## Shell and Terminal Configuration

This repository also includes installation scripts for Zsh and Tmux configurations that integrate seamlessly with Neovim.

### Zsh Installation

Install Zsh, Oh My Zsh, and configure with plugins:

**Arch Linux with pacman:**
```bash
cd ~/.config/nvim/zsh
./install.sh --distro arch --pkg-manager pacman
```

**Arch Linux with yay (AUR):**
```bash
./install.sh --distro arch --pkg-manager yay
```

**Ubuntu with apt:**
```bash
./install.sh --distro ubuntu --pkg-manager apt
```

**Ubuntu with Homebrew:**
```bash
./install.sh --distro ubuntu --pkg-manager homebrew
```

**Using short flags:**
```bash
./install.sh -d arch -p pacman
```

**Skip package installation (only install Oh My Zsh and plugins):**
```bash
./install.sh
```

### Tmux Installation

Install Tmux and TPM (Tmux Plugin Manager):

**Same flag system as Zsh:**
```bash
cd ~/.config/nvim/tmux
./install.sh --distro arch --pkg-manager pacman
./install.sh --distro ubuntu --pkg-manager apt
./install.sh -d ubuntu -p homebrew
```

**Skip package installation:**
```bash
./install.sh
```

### Supported Distributions

| Distribution | Default Package Manager | Alternatives |
|--------------|------------------------|--------------|
| Arch Linux   | `pacman`               | `yay`        |
| Ubuntu       | `apt`                  | `homebrew`   |
| Debian       | `apt`                  | `homebrew`   |
| Fedora       | `dnf`                  | `homebrew`   |

For more details on adding new distributions or customizing package management, see [lib/README.md](lib/README.md).

## File Structure

```
~/.config/nvim/
├── init.lua              # Entry point
├── lua/
│   ├── config/
│   │   └── lazy.lua       # Plugin manager setup
│   ├── core/
│   │   ├── options.lua    # Neovim options
│   │   ├── keymaps.lua    # Global keymaps
│   │   └── autocmds.lua   # Auto commands
│   └── plugins/           # Plugin configurations
│       ├── colorscheme.lua
│       ├── completion.lua
│       ├── comment.lua
│       ├── harpoon.lua
│       ├── lsp.lua
│       ├── metals.lua
│       ├── oil.lua
│       ├── telescope.lua
│       ├── treesitter.lua
│       └── ....
├── lib/
│   ├── package-manager.sh # Multi-distro package management
│   └── README.md          # Library documentation
├── zsh/
│   ├── install.sh         # Zsh installation script
│   └── .zshrc            # Zsh configuration
└── tmux/
    ├── install.sh         # Tmux installation script
    └── .tmux.conf        # Tmux configuration

```

## Setup Instructions

1. **Backup existing configuration** (if any):

   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. **Clone or copy this configuration** to `~/.config/nvim/`

3. **Start Neovim**:

   ```bash
   nvim
   ```

4. **Wait for plugins to install** - lazy.nvim will automatically install all plugins on first launch

5. **Restart Neovim** to ensure everything loads properly

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

## Troubleshooting

- **Plugin issues**: Run `:Lazy health` to check plugin status
- **LSP issues**: Run `:LspInfo` to check language server status
- **Treesitter issues**: Run `:TSInstallInfo` to check parser status

## Performance

This configuration is optimized for performance with:

- Lazy loading of plugins
- Efficient file searching with ripgrep
- Modern LSP setup with proper capabilities
- Minimal startup time with lazy.nvim
