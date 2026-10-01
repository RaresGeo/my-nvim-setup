# karabiner

Key remaps and launcher shortcuts through
[Karabiner-Elements](https://karabiner-elements.pqrs.org) (macOS only).

```bash
./install.sh karabiner
```

On the first run, open Karabiner-Elements once and approve its driver and
Input Monitoring. Dismissing notifications additionally needs Accessibility for
`karabiner_console_user_server` (System Settings > Privacy & Security >
Accessibility), since that is the process the hotkey's command runs as; macOS
offers to add it the first time Option+, is pressed.

| File | Does |
|------|------|
| `builtin-keyboard.json` | On the MacBook's own keyboard, swaps fn and left Ctrl so Ctrl sits in the corner. External keyboards are untouched: the built-in one is the only keyboard that reports no vendor or product ID. |
| `rules/launchers.json` | **Option+Enter**: a new Alacritty instance. **Option+Cmd+Enter**: one running tmux. **Option+Shift+B**: a new window of the default browser. |
| `rules/alacritty-close.json` | **Option+W** in Alacritty sends Cmd+W, so the window closes through Alacritty's own handling; it has no title bar for a window manager to press. |
| `rules/notifications.json` | **Option+,**: dismisses the newest notification banner. |
| `rules/omniwm.json` | **Option+0** focuses OmniWM workspace 10, **Option+Shift+0** moves the window there and follows it. OmniWM's own hotkeys only go up to nine workspaces, so these call `omniwmctl`. |
| `bin/dismiss-notification` | Presses the banner's own close action through NotificationCenter's accessibility tree; macOS has no API for it. |
| `bin/open-browser` | Works out the default browser and opens a new window the way that browser needs (Chromium, Firefox-based, Safari) |

Karabiner owns `~/.config/karabiner/karabiner.json`, so `install.sh` merges into
the selected profile rather than replacing it. The device entry and each rule
(matched by description) are swapped in, everything else is left alone, and the
old file is backed up whenever something changes. Change remaps here and re-run
the module rather than editing them in Karabiner's UI.

Descriptions double as rule identity, so the descriptions installed on the last
run are recorded in `~/.config/karabiner/.dotfiles-rules.json`. Renaming or
deleting a rule here therefore removes the old copy from the profile instead of
stranding it; rules added by hand in Karabiner's UI are not listed and survive.

Every launcher sits on Option, matching the [`omniwm`](../omniwm/README.md)
module, so Command is left entirely to macOS apps — Cmd+Shift+B in particular
goes back to toggling the browser's own bookmarks bar.

Karabiner intercepts at the HID level, so a combo it claims never reaches
OmniWM. The two these launchers take, Option+Shift+B and Option+, are therefore
left unassigned in `omniwm/settings.toml` rather than bound on both sides.

`rules/omniwm.json` goes the other way and drives OmniWM through its CLI.
OmniWM writes its whole hotkey roster into `settings.toml`, and that roster
stops at `switchWorkspace.8` — nine workspaces — so a tenth workspace cannot be
reached from OmniWM's own hotkeys at all. `omniwmctl` has no such limit, and
`switch-workspace anywhere` crosses monitors, which this needs: workspace 10
lives on the built-in display while 1–9 sit on the desk monitor. The path to
`omniwmctl` is absolute because Karabiner runs commands with launchd's bare
PATH, which has no Homebrew.
