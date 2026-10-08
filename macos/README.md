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
| `dock/com.dotfiles.dock-watch.plist.tpl` | Rendered to `~/Library/LaunchAgents/com.dotfiles.dock-watch.plist`, which runs `dockctl watch` — one resident process polling every 5s (the loop is in the script, not a `StartInterval`, so launchd has no respawns to throttle) |
| `theme/kanagawa/` | `~/.local/state/omarchy/current/theme`, the path nvim, zsh and Alacritty read colors from |
| `defaults.sh` | Fast key repeat, no press-and-hold popup, screenshots in `~/Pictures/Screenshots`, quittable Finder, Cmd+Space freed from Spotlight for Raycast |
| `build-alacritty.sh` | Builds the latest Alacritty release into `~/Applications` (Homebrew no longer ships it) |
| `doctor.sh` | Prints what to look at when something misbehaves |

## Docked and undocked

The desk keyboard is the signal, not the display: it sits behind a USB switch,
so the moment the switch hands it to the other machine it leaves this Mac's USB
tree — which is exactly the moment this stopped being the docked machine. No
display probing, and it is settled before the monitor has made up its mind.

A state change applies the Alacritty font size: 18 docked, 14 undocked, through
the generated `~/.config/alacritty/dock.toml` that `alacritty.toml` imports. The
ultrawide is 109 PPI at native 1x, so the app has to carry the readability
itself.

It also places OmniWM workspaces. Undocking does not unplug the Dell — the cable
stays and only its input changes — so macOS keeps it as a live display, and a
workspace parked there becomes invisible rather than gone. OmniWM cannot see any
of that, so `dockctl` owns placement outright and `omniwm/settings.toml` leaves
every workspace on `main` rather than pinning it to a display.

The wanted layout is declared, not remembered: docked, `WS_INTERNAL_WORKSPACES`
(10) stays on the built-in and everything else goes to the external panel;
undocked they all come home, because it is the only panel you can see. Each run
compares the live placement against that and moves only what is wrong, so it is
idempotent and self-correcting — a run that is already right does nothing, and a
run after something drifted puts it back. There is no record file to go stale.

Placement is reconciled on every poll, not only when the dock state or the set
of attached displays changes. OmniWM re-places workspaces onto whatever is
`main` of its own accord — reloading `settings.toml` is enough to set it off —
and neither of those signals moves when it does. Because the reconcile compares
against the wanted layout it costs one query when nothing is wrong, and it stays
quiet in the log unless it actually moves something. `dockctl status` prints the
display signature.

`dockctl detect` prints just `docked` or `undocked`, which is the contract other
scripts read rather than parsing `status`.

Docking also takes the desk microphone back. The Sound BlasterX G6 rides the same
USB switch as the keyboard — and the desk machine wants the opposite settings
from this one, because it monitors in software and therefore switches the card's
analog sidetone off while it holds it. Those are USB-audio-class controls, so
they are volatile and reset on every re-enumeration; crossing the switch is one.
Nothing can be assumed, so docking asserts a known state through `micctl`:
**unmuted, lamp white, sidetone on**.

Starting from unmuted matters because a mute left over from before the handover
is invisible *by design* — `micctl` mutes the microphone rather than the sink
precisely so that no app can see it — and the lamp, which is the only indicator
there is, is on the card that just came back from the other machine. Set
`MIC_APPLY=0` to leave the microphone alone.

Only on the transition, not every poll: asserting it on a five-second timer would
fight the mute key and unmute you a moment after you pressed it.

**But not at the moment of the transition.** The keyboard arriving does not mean
the card arrived — it is a separate device behind the same switch, and it is
listed by CoreAudio before it will accept a write. Asserting immediately is what
the 2026-10-08 docking cost: `microphone: could not reach it (could not mute
'Sound BlasterX G6')` in the dock log, and in the chain log the card appearing
and vanishing on a ten-second cycle, four cycles running, with the click and the
lamp dropping out that go with a card re-enumerating.

So the transition only **arms** the assertion. Every poll after it asks `micctl
ready` — attached, answering, and unchanged for twelve seconds — and does the
work on the first poll that says yes, giving up after `MIC_APPLY_DEADLINE`
(300 s). The five-second loop is the retry, so nothing sleeps inside an apply
where it would stall the workspace reconcile, and a card still restarting simply
never reads as settled. `dockctl status` says when an assertion is armed and what
it is waiting on; `audio/README.md` has where the twelve seconds comes from.

The flip side: moving a workspace to another display by hand gets undone within
five seconds. That is what owning placement means — set `DOCK_MOVE_WORKSPACES=0`
if you want to place things yourself.

`DOCK_MOVE_WORKSPACES=0` turns it off; `WS_INTERNAL_MATCH` is the substring that
identifies the built-in panel in OmniWM's display names. One wrinkle:
`omniwmctl workspace move-to-monitor` takes a *direction*, not a display, and the
usable direction follows neither the frame geometry nor the routing arrangement,
so it is discovered by trying and cached per target.

OmniWM refuses to move a workspace that is currently *shown* on its panel and
has windows on it — an empty one moves while visible, and the same workspace
moves once something else is shown in its place. So on that refusal `dockctl`
shows another workspace on that panel and retries. If it is the only workspace
there, an empty one is borrowed from elsewhere to take its place and a second
sweep sends the borrowed one home; empty workspaces are the safe thing to
borrow, since being empty they can be moved even while shown.

Two things this deliberately does **not** do, both decided by measuring:

| | |
|---|---|
| Zen's Gecko scale | `layout.css.devPixelsPerPx` at `-1.0` ("follow macOS") is already correct in both states — 2.0 on the built-in XDR, 1.0 on the Dell at native 1x. There is no per-state value to pick. An earlier version set 1.25 when docked, treating the pref as a readability boost; it *replaces* the backing scale instead of multiplying it, so it rendered Zen at 62.5% on the laptop. The pref is left static in `user.js`. |
| The ultrawide's input | This Mac cannot speak DDC to the Dell at all — every read fails at the I2C level, because the link is USB-C (DP Alt Mode) to HDMI and that active conversion does not carry the DDC sideband. The desktop can, in both directions, so it owns the handover from its side. For the record, the panel's VCP `0x60` values are dp1=`0x0f`, hdmi1=`0x11`, hdmi2=`0x12`; this Mac is on HDMI-1. |

```bash
dockctl status      # detected state, what is applied, any armed mic assertion
dockctl probe       # what the detector sees -- run this at the desk
dockctl apply       # apply if the state changed (what the agent runs)
dockctl dock        # force a state, ignoring the hardware
dockctl undock
```

The keyboard's USB ids and both font sizes are environment variables at the top
of `dockctl`; `dockctl probe` prints the ids to put there. The agent polls
rather than waiting on an event because launchd has no USB trigger, and `apply`
is a ~17ms no-op when nothing changed.

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
