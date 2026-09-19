# omniwm

[OmniWM](https://github.com/BarutSRB/OmniWM), a tiling window manager for
Apple Silicon Macs with real Hyprland-style dwindle (BSP) and Niri-style
scrolling layouts. Replaced the `aerospace` module: AeroSpace has no dwindle
layout, and OmniWM does.

```bash
./install.sh omniwm
```

On first launch, grant OmniWM Accessibility when macOS asks. Settings live
in `settings.toml` (TOML, live-reloaded while OmniWM runs) and apply
instantly on save — no restart needed, except when the change is to the
`workspaces` array or `appRules`, which only fully reload on a fresh launch
(`killall OmniWM && open -a OmniWM`).

Every workspace defaults to **dwindle**. Caps Lock is wired as OmniWM's
"Hyper" trigger (hold it for Control+Option+Shift+Command).

## Keys

Everything is on **Option**, so macOS app shortcuts on Command stay
untouched — same convention the AeroSpace module used.

| Keys | Does |
|------|------|
| option + h/j/k/l | Focus left/down/up/right |
| option + shift + h/j/k/l | Move the window |
| option + 1–9 | Switch workspace |
| option + shift + 1–9 | Move the window to a workspace and follow it |
| option + tab / option + shift + tab | Next / previous workspace |
| control + option + tab | Jump back to the last workspace |
| option + w | Close window |
| option + f | Fullscreen |
| option + t | Toggle floating |
| option + / | Toggle split orientation (`toggleSplit`) |
| option + shift + / | Swap the active split (`swapSplit`) — try both, whichever actually flips your current layout |
| option + - / = | Shrink / grow the container span |
| control + option + l | Cycle workspace layout (dwindle / niri / default) |
| control + option + t | Toggle column tabbed (niri) |
| control + option + space | Command palette |
| option + \` | Quake terminal |
| option + shift + o | Overview |

Everything else is an OmniWM default — see Settings > Hotkeys in the app for
the full list (there's no hotkey-triggered way to print it).

## Karabiner pairs with this

The `karabiner` module's launcher rules assume this module: **Option+Return**
opens a new Alacritty window, **Option+Cmd+Return** opens one running tmux,
and **Option+W** sends Cmd+W instead of the WM's own close command when
Alacritty is frontmost, since Alacritty has no title bar for OmniWM to press
a close button on.

## Known limitations (not fixable from config)

- Closing the focused window can jump you back to whatever workspace was
  focused before you switched here — an internal `FocusPolicyEngine`
  decision baked into this (pre-1.0) build, not a macOS restriction. No
  exposed setting changes it; worth filing upstream if it bothers you.
- No standalone hotkey for clipboard history — it only lives inside the
  command palette.
