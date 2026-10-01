# macos

The base layer for a Mac that mostly lives in the terminal. Key remaps and
window management are separate modules: [`karabiner`](../karabiner/README.md)
and [`omniwm`](../omniwm/README.md).

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
| `--no-dock-agent` | Skip the launchd dock watcher (`dockctl` is still installed) |

## What it does

| File | Linked to / effect |
|------|--------------------|
| `Brewfile` | bash, Nerd Font, CLI tools (fzf, zoxide, eza, bat, btop, gh, mise, herdr, ...) |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml`; imports `dock.toml` for the font size, so the size is not set here |
| `dock/dockctl` | `~/.local/bin/dockctl`, the docked/undocked switch (see below) |
| `dock/com.dotfiles.dock-watch.plist.tpl` | Rendered to `~/Library/LaunchAgents/com.dotfiles.dock-watch.plist`, which runs `dockctl apply` every 5s |
| `theme/kanagawa/` | `~/.local/state/omarchy/current/theme`, the path nvim, zsh and Alacritty read colors from |
| `defaults.sh` | Fast key repeat, no press-and-hold popup, screenshots in `~/Pictures/Screenshots`, quittable Finder |
| `build-alacritty.sh` | Builds the latest Alacritty release into `~/Applications` (Homebrew no longer ships it) |
| `doctor.sh` | Prints what to look at when something misbehaves |

## Docked and undocked

The desk keyboard is the signal, not the display: it sits behind a USB switch,
so the moment the switch hands it to the other machine it leaves this Mac's USB
tree — which is exactly the moment this stopped being the docked machine. No
display probing, and it is settled before the monitor has made up its mind.

A state change applies three things:

| | |
|---|---|
| Alacritty font size | 18 docked, 14 undocked, through the generated `~/.config/alacritty/dock.toml` that `alacritty.toml` imports. The ultrawide is 109 PPI at native 1x, so the app has to carry the readability itself. |
| Zen's Gecko scale | `layout.css.devPixelsPerPx` in the profile's `user.js`; `-1.0` undocked follows macOS, `1.25` docked. Applies on Zen's next launch. |
| The ultrawide's input | On undock only: hands the monitor to the other machine over DDC/CI via `m1ddc`. One-way on purpose — the other machine switches it back itself, so we only ever talk to the monitor while this Mac still owns the cable. |

```bash
dockctl status      # detected state, and what is currently applied
dockctl probe       # what the detector sees -- run this at the desk
dockctl apply       # apply if the state changed (what the agent runs)
dockctl dock        # force a state, ignoring the hardware
dockctl undock
```

The keyboard's USB ids, both font sizes, both scales and the monitor input are
environment variables at the top of `dockctl`; `dockctl probe` prints the ids to
put there. The agent polls rather than waiting on an event because launchd has
no USB trigger, and `apply` is a ~17ms no-op when nothing changed.

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
