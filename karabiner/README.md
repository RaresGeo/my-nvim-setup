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
| `devices/builtin-keyboard.json` | On the MacBook's own keyboard, swaps fn and left Ctrl so Ctrl sits in the corner. External keyboards are untouched: the built-in one is the only keyboard that reports no vendor or product ID. |
| `devices/logitech-mouse.json` | Flips the scroll wheel on the Logitech receiver's mouse (`046d:c547`), both axes. macOS keeps a single `com.apple.swipescrolldirection` shared by the trackpad and every mouse, so this is the only way to have natural scrolling on the trackpad and a conventional wheel on the mouse. |
| `rules/launchers.json` | **Option+Enter**: a new Alacritty instance. **Option+Cmd+Enter**: one running tmux. **Option+Shift+B**: a new window of the default browser. |
| `rules/alacritty-close.json` | **Option+W** in Alacritty sends Cmd+W, so the window closes through Alacritty's own handling; it has no title bar for a window manager to press. |
| `rules/notifications.json` | **Option+,**: dismisses the newest notification banner. |
| `rules/omniwm.json` | **Option+0** focuses OmniWM workspace 10, **Option+Shift+0** moves the window there and follows it. OmniWM's own hotkeys only go up to nine workspaces, so these call `omniwmctl`. |
| `rules/clipboard.json` | **Option+C** and **Option+V** copy and paste in every app, so both sit on Option like the rest of this setup. **Option+Ctrl+V** opens Raycast's clipboard history. |
| `rules/microphone.json` | **Option+B** mutes and unmutes the microphone, through the [`audio`](../audio/README.md) module's `micctl`. It sets CoreAudio's mute flag on the default input, which here is the chain's sink, so it silences exactly what every app reads. The cost is `backward-word` on Alt+B in the shell, which is still on Ctrl+Left; `audio/README.md` has the full accounting. |
| `bin/dismiss-notification` | Presses the banner's own close action through NotificationCenter's accessibility tree; macOS has no API for it. |
| `bin/open-browser` | Works out the default browser and opens a new window the way that browser needs (Chromium, Firefox-based, Safari) |

## Copy, paste and clipboard history

**Option+C** and **Option+V** are rewritten to Cmd+C and Cmd+V at the HID
level, so every app still receives its own native shortcut and nothing has to
be configured per app. Option is the modifier everything else here lives on,
which is the whole point: one combo copies everywhere.

It is not free, and the cost is all inside Alacritty, because
`option_as_alt = "Both"` means Option arrives in the shell as Alt:

- **Alt+C is gone.** It was `fzf-cd-widget` (fzf's jump-to-subdirectory), from
  the `fzf --zsh` bindings `zsh/.zshrc` sources. The `fcd` function a few lines
  above it in the same file does the same job, which is why this was the
  binding to give up.
- **Alt+V was never bound** — `bindkey "\ev"` reports `undefined-key` — so
  pasting costs nothing.
- Option+C no longer types **ç**.

Nothing else in the stack wants either key: `herdr/config.toml` uses Alt only
with Enter, Esc, the digits and the arrows, nvim has no `<M-c>`/`<M-v>`, and
tmux has no Alt bindings at all.

**Option+Ctrl+V** opens clipboard history, on either Control — the MacBook's
built-in keyboard has no right Control key, so requiring that one would have
left the combo dead undocked. It runs a Raycast deeplink rather than pressing a
hotkey, because neither clipboard history can be bound directly:

- **OmniWM's cannot be bound at all.** `[clipboard] historyEnabled = true` in
  `omniwm/settings.toml` turns it on, but OmniWM writes its entire hotkey
  roster into that file and there is no clipboard id anywhere in it, not even
  as `Unassigned`. It is reachable only from the command palette
  (**Control+Option+Space**), so there is nothing for a hotkey to point at.
- **Raycast's hotkeys are not reachable from this repo.** They live in
  `settings_v2.db` under `~/Library/Application Support/com.raycast.macos/`,
  which is SQLCipher-encrypted — the header is random bytes, not
  `SQLite format 3`. Its plist holds only window geometry.

So the rule shells out to the deeplink, which needs no Raycast-side setup:

```bash
open "raycast://extensions/raycast/clipboard-history/clipboard-history"
```

That id is confirmed rather than guessed: the same deeplink with a bogus
command name leaves the frontmost app untouched, while the real one brings
Raycast up.

Both Option+V and Option+Ctrl+V are `"optional": []`, so Option+Ctrl+V never
falls through to the paste rule — an extra modifier stops a match outright,
which is also why Option+Shift+B does not trip the plain-Option rules.

Karabiner owns `~/.config/karabiner/karabiner.json`, so `install.sh` merges into
the selected profile rather than replacing it. Each `devices/*.json` entry
(matched by its `identifiers`) and each rule (matched by description) are
swapped in, everything else is left alone, and the old file is backed up
whenever something changes. Change remaps here and re-run
the module rather than editing them in Karabiner's UI.

Descriptions double as rule identity, so the descriptions installed on the last
run are recorded in `~/.config/karabiner/.dotfiles-rules.json`. Renaming or
deleting a rule here therefore removes the old copy from the profile instead of
stranding it; rules added by hand in Karabiner's UI are not listed and survive.

Every launcher sits on Option, matching the [`omniwm`](../omniwm/README.md)
module, so Command is left entirely to macOS apps — Cmd+Shift+B in particular
goes back to toggling the browser's own bookmarks bar.

Karabiner intercepts at the HID level, so a combo it claims never reaches
OmniWM. The three claimed here, Option+Shift+B, Option+, and Option+B, are
therefore left unassigned in `omniwm/settings.toml` rather than bound on both
sides.

`rules/omniwm.json` goes the other way and drives OmniWM through its CLI.
OmniWM writes its whole hotkey roster into `settings.toml`, and that roster
stops at `switchWorkspace.8` — nine workspaces — so a tenth workspace cannot be
reached from OmniWM's own hotkeys at all. `omniwmctl` has no such limit, and
`switch-workspace anywhere` crosses monitors, which this needs: workspace 10
lives on the built-in display while 1–9 sit on the desk monitor. The path to
`omniwmctl` is absolute because Karabiner runs commands with launchd's bare
PATH, which has no Homebrew.
