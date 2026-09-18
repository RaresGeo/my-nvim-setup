# aerospace

[AeroSpace](https://github.com/nikitabobko/AeroSpace), an i3-like tiling window
manager for macOS, with a deliberately small config. It is the starting point
for making the Mac feel a little like Hyprland, one habit at a time.

```bash
./install.sh aerospace
```

On first launch, grant AeroSpace Accessibility permission when macOS asks.
Edits to `aerospace.toml` apply with alt+shift+; then Esc.

## Keys

Everything is on **alt** (Option; the Alt key on a PC keyboard), so app
shortcuts on Command are untouched.

| Keys | Does |
|------|------|
| alt + h/j/k/l | Focus left/down/up/right |
| alt + shift + h/j/k/l | Move the window |
| alt + 1–9 | Switch workspace |
| alt + shift + 1–9 | Move the window to a workspace and follow it |
| alt + tab / alt + shift + tab | Next / previous workspace |
| alt + w | Close window, quitting the app on its last window, and stay on this workspace |
| alt + f | Fullscreen |
| alt + t | Toggle floating |
| alt + / | Toggle split direction |
| alt + , | Accordion (stacked) layout |
| alt + - / = | Shrink / grow |
| alt + shift + ; | Service mode: Esc reload, r flatten, f float, Backspace close others |

## Toward Hyprland: things to work through

1. **Which key is the window-manager key.** alt collides with the terminal:
   herdr uses alt+1–9 and alt+Enter, and zsh uses alt for word motions. The
   options: stay on alt and move herdr to its prefix keys; use Super (which
   macOS calls Command) and give up some app shortcuts; or have Karabiner turn
   one key into a dedicated modifier.
2. **Launchers.** Super+Enter and Super+Shift+B currently come from Karabiner.
   AeroSpace can launch apps too (`exec-and-forget`), which would keep all
   desktop keys in one file.
3. **Layout feel.** AeroSpace splits in i3 trees, not Hyprland's dwindle.
   Worth seeing how much `default-root-container-orientation` and the
   normalization settings get close enough.
4. **Workspaces per monitor** once the dock arrives
   (`workspace-to-monitor-force-assignment`).
5. **Looks.** An active-window border and gap sizes.
6. **Scratchpad.** Hyprland's special workspace has no direct equivalent.
