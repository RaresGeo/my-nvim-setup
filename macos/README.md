# macos

The base layer for a Mac that mostly lives in the terminal. Key remaps and
window management are separate modules: [`karabiner`](../karabiner/README.md)
and [`aerospace`](../aerospace/README.md).

```bash
brew install bash                       # the installers need bash 4+; macOS ships 3.2
./install.sh macos --with-alacritty     # first time
./install.sh macos                      # afterwards
```

| Flag | Effect |
|------|--------|
| `--no-packages` | Skip `brew bundle` |
| `--no-defaults` | Skip `defaults.sh` |
| `--with-alacritty` | Build Alacritty from source (`build-alacritty.sh`) |

## What it does

| File | Linked to / effect |
|------|--------------------|
| `Brewfile` | bash, Nerd Font, CLI tools (fzf, zoxide, eza, bat, btop, gh, mise, herdr, ...) |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `theme/kanagawa/` | `~/.local/state/omarchy/current/theme`, the path nvim, zsh and Alacritty read colors from |
| `defaults.sh` | Fast key repeat, no press-and-hold popup, screenshots in `~/Pictures/Screenshots`, quittable Finder |
| `build-alacritty.sh` | Builds the latest Alacritty release into `~/Applications` (Homebrew no longer ships it) |
| `doctor.sh` | Prints what to look at when something misbehaves |

## Terminal keys

Alacritty keeps the Linux bindings: Ctrl+Shift+Space vi mode, Ctrl+Shift+C/V,
Ctrl+Shift+N new window, Ctrl+Shift+F/B search. On a PC keyboard macOS reads
Super as Command and Alt as Option; `option_as_alt` makes Alt a real Meta in the
terminal, so herdr's `alt+...` keys, zsh word motions and nvim `<M-...>` work
as on Linux.

## When shortcuts stop working

Run `macos/doctor.sh`. If it reports **secure input** held by some app, no
other app sees keystrokes, so every global shortcut goes dead. Quit that app, or
turn off Terminal → Secure Keyboard Entry if it is Terminal.
