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
| option + s | Toggle scratchpad 1 — Google Calendar lives there, see below |
| option + shift + s | Assign/unassign the focused window to scratchpad 1 |
| option + w | Close window |
| option + f | Fullscreen |
| option + t | Toggle floating |
| option + / | Toggle split orientation (`toggleSplit`) |
| option + shift + / | Swap the active split (`swapSplit`) — try both, whichever actually flips your current layout |
| option + - / = | Shrink / grow the container span |
| control + option + l | Cycle workspace layout (dwindle / niri / default) |
| control + option + t | Toggle column tabbed (niri) |
| control + option + space | Command palette |
| option + shift + o | Overview |

Everything else is an OmniWM default — see Settings > Hotkeys in the app for
the full list (there's no hotkey-triggered way to print it).

**Option+\` is deliberately left free.** OmniWM's quake terminal shipped on it
by default, and OmniWM grabs its hotkeys globally, so nothing reaches the
focused app — which silently killed Neovim's `<M-\`>` terminal-split toggle
(`nvim/lua/plugins/telescope.lua`). `toggleQuakeTerminal` is `Unassigned` and
`[quakeTerminal] enabled = false`; don't rebind it here.

## Karabiner pairs with this

The `karabiner` module's launcher rules assume this module: **Option+Return**
opens a new Alacritty window, **Option+Cmd+Return** opens one running tmux,
and **Option+W** sends Cmd+W instead of the WM's own close command when
Alacritty is frontmost, since Alacritty has no title bar for OmniWM to press
a close button on.

Karabiner intercepts at the HID level, so a combo it claims never reaches
OmniWM. Two of OmniWM's defaults sit on combos the `karabiner` module now
takes, and are left `Unassigned` here rather than bound on both sides:

| Combo | Karabiner uses it for | OmniWM command given up |
|-------|-----------------------|-------------------------|
| option + shift + b | A new browser window | `balanceSizes` |
| option + , | Dismiss the newest notification | `cycleSizeBackward` |

`cycleSizeForward` keeps **option + .**, so cycling still works, one way
round.

## The workspace bar, the notch, and the external panel

The bar is set to `position = "overlappingMenuBar"`, which on the built-in
panel would park it behind the notch. `notchMode = "moveBelowMenuBar"` fixes
that, and it is applied per display off OmniWM's own `hasNotch` — true for the
built-in, false for the Dell — so the Dell keeps its bar over its own menu bar.
Measured, not assumed: the Dell's bar window sits inside the menu bar strip in
both notch modes, because the setting does nothing on a panel with no notch.

`reserveLayoutSpace` is the one that mattered. It is a global switch, so the
bar took a 24pt band off the top of *both* panels — 19pt of tiling area, since
the 5pt outer gap is absorbed into the band. The laptop needs that; on the Dell
it bought nothing, the band sitting under a menu bar the bar already overlaps.
So the Dell gets a per-display override:

```toml
[[monitorBarOverrides]]
id = "7A1F0C2E-9B4D-4E61-A3C8-5D2F6B8E1049"
monitorDisplayUUID = "BB1AD357-346B-440B-B325-BBDA76A066EC"
monitorName = "DELL S3422DWG"
reserveLayoutSpace = false
```

Everything about that block is load-bearing and none of it is documented
upstream, so:

- **`id` is required and is the override row's own UUID**, not the display's.
  Any valid UUID works; it just has to be there.
- **`monitorName` is required too**, but the match is made on
  `monitorDisplayUUID`. A block with the right name and no UUID parses and
  then silently applies to nothing.
- Swap the monitor and the UUID changes. Read the new one out of the
  `[[routing.arrangements.monitors]]` block OmniWM writes for that display —
  it records `monitorName` next to `monitorDisplayUUID`.
- `position` is **not** per-display overridable. `notchMode`,
  `reserveLayoutSpace`, `height`, `enabled`, `showLabels`,
  `hideEmptyWorkspaces`, `windowLevel`, the opacity and offset knobs are.

An invalid `settings.toml` is rejected whole and in silence — the app keeps the
last good copy and nothing in the UI says so. The reason only shows up in the
log, which is the fastest way to debug an edit to this file:

```bash
log stream --predicate 'subsystem == "com.barut.OmniWM"' --level debug
```

It names the exact key, e.g. `monitorBarOverrides[0].id: Key 'id' not found`.

Nothing here is dock-state dependent, so `dockctl` stays out of it: both panels
are configured correctly whether or not the Dell is attached.

## The calendar scratchpad

**Option+S** brings up Google Calendar. It is a Chrome PWA, not a browser
window — installed from `calendar.google.com` via Chrome's *Cast, Save and
Share > Install page as app*, which gives it its own bundle in
`~/Applications/Chrome Apps.localized` and, importantly, its own bundle ID:

```
com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep
```

That ID is why this works at all. A `--app=` window launched from the Chrome
binary would still be `com.google.Chrome` to both macOS and OmniWM, so nothing
could single it out from an ordinary browser window. A real PWA install is a
separate app as far as the WM is concerned.

Chrome's install flow is UI-only — there is no flag for it — so `install.sh`
cannot create it and only warns when it is missing.

### Why this needs a daemon

`scratchpad-pin` is a watcher, because nothing in OmniWM can express "this app
belongs in a scratchpad". Checked against 0.7.2:

- **`appRules` has no scratchpad action.** It can pin an app to a workspace
  (`--assign-to-workspace`), set its layout and its initial span, and nothing
  else — `omniwmctl query rule-actions` is the full list.
- **The only scratchpad command acts on the focused window.**
  `omniwmctl command scratchpad assign <slot>` takes no window argument, so
  the watcher has to focus the window first and put focus back afterwards.
- **Membership is never written to disk.** `settings.toml` round-trips
  `[scratchpads]` and `[scratchpads.labels]`, but the members are not in the
  schema and assigning does not rewrite the file at all. Nor does
  `~/.local/state/omniwm/runtime-state.json`. So the assignment dies with the
  window, and with every OmniWM restart.

So the watcher subscribes to `windows-changed` and re-applies the assignment.
It leans on two things worth knowing:

- `subscribe` sends an initial event, so every reconnect sweeps immediately.
  A reconnect *is* the OmniWM-restarted signal, and that is when the list of
  already-pinned windows is forgotten and everything is pinned again.
- Each window is pinned once per OmniWM session, so unassigning something by
  hand with **Option+Shift+S** sticks instead of being fought back.

A window assigned into a slot that is currently *revealed* stays on screen,
which at login would leave the calendar floating over everything, so the
watcher conceals the slot when a freshly pinned window comes up visible.

The apps are opened once, when the watcher starts, so **quitting the calendar
keeps it quit** — the watcher pins windows, it does not resurrect an app you
closed on purpose, the same way it does not undo an Option+Shift+S. Start it
again however you like and the resident watcher pins it within a second or
two; otherwise it is back at the next login.

Two traps, if you extend this:

- **`query windows --scratchpad` is not trustworthy.** It returned an empty
  list while scratchpad members were plainly present and visible. Read
  `scratchpadIndex` off `query windows` instead, which is what the script does.
- **`assign` acts on whatever is focused the moment it runs**, and focus
  changes are asynchronous. The script polls until the window it asked for is
  actually focused before firing, or it would pin a bystander.

`[scratchpads.labels]` *is* persisted, so slot 1's bar pill is named:

```toml
[scratchpads.labels]
1 = "Calendar"
```

## Known limitations (not fixable from config)

- Closing the focused window can jump you back to whatever workspace was
  focused before you switched here — an internal `FocusPolicyEngine`
  decision baked into this (pre-1.0) build, not a macOS restriction. No
  exposed setting changes it; worth filing upstream if it bothers you.
- No standalone hotkey for clipboard history — it only lives inside the
  command palette.
