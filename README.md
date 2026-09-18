# Dotfiles

Neovim, tmux, zsh, herdr and Hyprland configuration, plus a macOS base layer,
installed by symlink.

This started life as just a neovim config and grew, so it is now organised as a
set of independent modules. Each module owns a directory with its config and an
`install.sh`; the top-level `install.sh` just runs them in a sensible order.

Nothing here assumes the repo lives at a particular path — every script resolves
the repo root from its own location — so the checkout can sit at
`~/.config/dotfiles`, `~/dotfiles`, or anywhere else.

## Install

```bash
git clone <this-repo> ~/.config/dotfiles
cd ~/.config/dotfiles
./install.sh --all
```

Or pick modules:

```bash
./install.sh nvim tmux
./install.sh --list          # what applies to this host
./install.sh --help
```

Useful flags:

| Flag | Effect |
|------|--------|
| `--all` | Every module applicable to this host |
| `--no-packages` | Skip system package installation |
| `-d`, `--distro` | Override distro detection |
| `-p`, `--pkg-manager` | Override package manager (e.g. `yay` over `pacman`) |

Distro and package manager are detected automatically; the flags are only there
for overriding that. Unrecognised flags are passed straight through to the
modules, so `./install.sh herdr --with-claude` and `./install.sh nvim
--no-plugins` work as expected.

Installs are idempotent. Anything real already sitting at a symlink target is
moved aside to `<path>.bak.<timestamp>` first.

### Migrating from the old layout

This repo used to *be* `~/.config/nvim`. It cannot stay there any more, because
that path is now a symlink target:

```bash
mv ~/.config/nvim ~/.config/dotfiles
~/.config/dotfiles/install.sh --all
```

## Modules

| Module | Installs | Host |
|--------|----------|------|
| [`nvim`](nvim/README.md) | `~/.config/nvim`, lazy.nvim plugins | any |
| `tmux` | `~/.tmux.conf`, TPM and plugins | any |
| `zsh` | `~/.zshrc`, oh-my-zsh and plugins | any |
| `herdr` | `~/.config/herdr/config.toml` | Omarchy (ships with it) or macOS (Homebrew) |
| `omarchy` | Hyprland overrides, theme hooks | Omarchy |
| [`macos`](macos/README.md) | Alacritty, theme snapshot, CLI tools, system defaults | macOS |
| [`karabiner`](karabiner/README.md) | Built-in keyboard remap, Cmd+Enter / Cmd+Shift+B launchers | macOS |
| [`aerospace`](aerospace/README.md) | Tiling window manager, minimal config | macOS |

## Omarchy

The setup is built for [Omarchy](https://omarchy.org/) Quattro (4.x) but does
not require it. Omarchy-specific work is isolated in two places:

- `omarchy/` — a module that is Omarchy-only by definition: the personal
  Hyprland overrides and the theme-set hook.
- `<module>/omarchy.sh` — optional per-module integration, sourced only when
  `lib/os.sh` confirms an Omarchy Quattro host. On a plain Arch, Ubuntu, Fedora
  or macOS box these are skipped and the module installs without them.

So `tmux` and `zsh` install their configs everywhere, and additionally register
their themed templates with Omarchy when it is present.

### What Omarchy drives

Colors are not checked into this repo. Omarchy generates them from the active
theme's palette through templates that the modules register:

| Template | Generates |
|----------|-----------|
| `tmux/tmux.conf.tpl` | tmux status line colors |
| `zsh/zsh-colors.tpl` | agnoster prompt segment colors |

Neovim resolves its colorscheme at runtime from
`~/.local/state/omarchy/current/theme/` — see `nvim/lua/plugins/colorscheme.lua`.

`omarchy/hooks/theme-set.d/reload-terminal-apps` is what makes a theme switch
land without restarts: it re-sources tmux, sends a synthetic `FocusGained` to
running neovim instances, and signals zsh with `SIGUSR1`.

### Hyprland

Only the files that actually diverge from Omarchy's defaults are tracked:
`bindings.lua`, `input.lua`, `looknfeel.lua`, `autostart.lua`. Omarchy's
`hyprland.lua` requires each of these after loading its own defaults, so
upstream improvements keep arriving.

Deliberately not tracked:

- `hyprland.lua` — unmodified from the default; letting Omarchy own it means
  updates to the entrypoint are not blocked by this repo.
- `monitors.lua` — machine-specific display layout.

`shell.json`, disabled plugins and other per-device Omarchy settings are also
left out, for the same reason.

## Layout

```
.
├── install.sh              # orchestrator
├── lib/
│   ├── common.sh           # repo root resolution, logging, symlinking
│   ├── os.sh               # distro + Omarchy detection
│   ├── package-manager.sh  # cross-distro package installation
│   └── README.md
├── nvim/                   # -> ~/.config/nvim
│   ├── install.sh
│   ├── init.lua
│   ├── lua/{config,core,plugins}/
│   ├── lsp/                # per-server LSP configs
│   └── after/ftplugin/
├── tmux/
│   ├── install.sh
│   ├── omarchy.sh          # Omarchy-only extras
│   ├── .tmux.conf          # -> ~/.tmux.conf
│   └── tmux.conf.tpl       # themed template
├── zsh/
│   ├── install.sh
│   ├── omarchy.sh
│   ├── .zshrc              # -> ~/.zshrc
│   └── zsh-colors.tpl      # themed template
├── herdr/
│   ├── install.sh
│   └── config.toml         # -> ~/.config/herdr/config.toml
├── omarchy/
│   ├── install.sh
│   ├── hypr/*.lua          # -> ~/.config/hypr/
│   └── hooks/theme-set.d/  # -> ~/.config/omarchy/hooks/theme-set.d/
├── macos/
│   ├── install.sh
│   ├── Brewfile
│   ├── alacritty/          # -> ~/.config/alacritty/
│   ├── theme/kanagawa/     # -> ~/.local/state/omarchy/current/theme
│   └── defaults.sh, build-alacritty.sh, doctor.sh
├── karabiner/
│   ├── install.sh          # merges into ~/.config/karabiner/karabiner.json
│   ├── builtin-keyboard.json
│   ├── rules/*.json        # -> ~/.config/karabiner/assets/complex_modifications/
│   └── bin/open-browser    # -> ~/.local/bin/open-browser
└── aerospace/
    ├── install.sh
    ├── aerospace.toml      # -> ~/.config/aerospace/aerospace.toml
    └── bin/                # -> ~/.local/bin/
```

## Adding a module

1. `mkdir mymodule` and put the config in it.
2. Write `mymodule/install.sh`:

   ```bash
   #!/bin/bash
   set -e
   source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
   module_init "${BASH_SOURCE[0]}"

   parse_install_flags "$@"
   install_packages "mymodule_essentials"   # optional, see lib/README.md

   link mymodule/config "$HOME/.config/mymodule/config"
   run_integration omarchy                  # optional
   ```

3. Add it to `MODULE_ORDER` in the top-level `install.sh` (and to
   `OMARCHY_ONLY` or `MACOS_ONLY` if it only applies to one host).

## Supported distributions

| Distribution | Default package manager | Alternatives |
|--------------|------------------------|--------------|
| Arch | `pacman` | `yay` |
| Ubuntu | `apt` | `homebrew` |
| Debian | `apt` | `homebrew` |
| Fedora | `dnf` | `homebrew` |
| RHEL | `dnf` | — |
| macOS | `homebrew` | — |

On macOS, install `bash` from Homebrew first: the installers need bash 4+, and
`lib/common.sh` re-executes under Homebrew's bash when `/bin/bash` is 3.2.

Derivatives resolve through `ID`/`ID_LIKE` in `/etc/os-release`. See
[lib/README.md](lib/README.md) for adding distributions or package groups.
