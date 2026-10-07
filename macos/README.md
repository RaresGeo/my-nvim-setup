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
| `defaults.sh` | Fast key repeat, no press-and-hold popup, screenshots in `~/Pictures/Screenshots`, quittable Finder, US keyboard layout |
| `keyboard-layout.sh` | Makes one keyboard layout the only one enabled (default `com.apple.keylayout.US`) |
| `build-alacritty.sh` | Builds the latest Alacritty release into `~/Applications` (Homebrew no longer ships it) |
| `doctor.sh` | Prints what to look at when something misbehaves |

## Keyboard layout

The internal keyboard reports `KeyboardLanguage "British"`, so macOS chose the
British layout at setup: £ on Shift+3, `"` on Shift+2, `@` on Shift+'. This repo
assumes the US positions, so `defaults.sh` declares them.

```bash
macos/keyboard-layout.sh                                 # US, the default
macos/keyboard-layout.sh com.apple.keylayout.British     # back again
```

It leaves the chosen layout as the *only* one enabled, because a second one
means a flag in the menu bar and a switch key the old layout can return
through. Non-keyboard input sources are untouched -- the character palette and
Dictation share that list, and dropping those would take away the emoji picker
rather than a layout.

This is not a `defaults write`. The enabled and selected sources do live in
`com.apple.HIToolbox`, but the running input system holds them in memory and
writes that domain out itself, so a write from outside is ignored until the next
login and then usually overwritten. Text Input Services is the supported way
in, so the script compiles a short Carbon helper (`cc`, from the command line
tools this module already needs) and runs it.

Three keys still disagree with the printed legends, which is the cost of a US
layout on British hardware: Shift+2 gives `@` where the key says `"`, Shift+'
gives `"` where it says `@`, and the key left of Return gives `\` and `|` where
it says `#` and `~`. The backtick and `§` keys keep their legends, because
Karabiner reports the virtual keyboard as ISO (`keyboard_type_v2`) and macOS
then uses the US layout's ISO table, where those two sit exactly where a
British keyboard puts them.

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
