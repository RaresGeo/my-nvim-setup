# karabiner

Key remaps and launcher shortcuts through
[Karabiner-Elements](https://karabiner-elements.pqrs.org) (macOS only).

```bash
./install.sh karabiner
```

On the first run, open Karabiner-Elements once and approve its driver and
Input Monitoring.

| File | Does |
|------|------|
| `builtin-keyboard.json` | On the MacBook's own keyboard, swaps fn and left Ctrl so Ctrl sits in the corner. External keyboards are untouched: the built-in one is the only keyboard that reports no vendor or product ID. |
| `rules/launchers.json` | **Cmd+Enter**: a new Alacritty instance. **Cmd+Shift+B**: a new window of the default browser. |
| `bin/open-browser` | Works out the default browser and opens a new window the way that browser needs (Chromium, Firefox-based, Safari) |

Karabiner owns `~/.config/karabiner/karabiner.json`, so `install.sh` merges into
the selected profile rather than replacing it. The device entry and each rule
(matched by description) are swapped in, everything else is left alone, and the
old file is backed up whenever something changes. Change remaps here and re-run
the module rather than editing them in Karabiner's UI.

With a PC keyboard, Cmd is the Super key, so the launchers are Super+Enter and
Super+Shift+B, as on Omarchy.
