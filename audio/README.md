# audio

Mute, sidetone and the mute lamp for the desk microphone on macOS. Apps talk to
the sound card directly — there is no virtual device, no processing chain and
nothing resident.

```bash
./install.sh audio
```

| File | Does |
|------|------|
| `bin/micctl` | `mute`, `sidetone`, `claim`, `ready`, `status`. One-shot; nothing runs in the background. |
| `src/coreaudio-ctl.c` | Reads and sets a named device's capture mute flag, its input source, its sidetone and its input gain. macOS shows all of them in System Settings but ships no CLI for any, and `SwitchAudioSource` can only reach the mute flag on whatever is the *default* input. Built by `install.sh`. |
| `~/.config/audio/local.conf` | Device names and colours for this machine. Seeded by `install.sh`, not tracked: it is the only per-host part. |

The **Option+B** mute key is a Karabiner rule, so it lives in that module
(`karabiner/rules/microphone.json`) the way `rules/omniwm.json` drives the
omniwm module's CLI. Install both to get the key as well as the CLI.

## There used to be a gate here

This module was a gated-microphone chain: physical mic → SoX highpass and noise
gate → BlackHole 2ch, with BlackHole as the system default input so every app
picked the gate up with no per-app setup at all. It worked, it measured well,
and it is in the git history if it is ever wanted back.

It went on 2026-10-08, and the reason is worth keeping because the obvious
reading of it is wrong.

The card kept re-enumerating on arrival at this Mac — clicking, lamp dropping
out, off the USB bus and back on a ten-second cycle. **The chain was not the
cause.** That was measured, not assumed: with both agents booted out and no
`sox`, `micctl` or `dockctl` process running at all, a handover produced

| | |
|---|---|
| 13:39:27 | gone (switched to the desk machine) |
| 13:39:52 | back on the Mac |
| 13:39:56 | **dropped after 4s** |
| 13:40:02 | back |
| 13:40:06 | **dropped after 4s** |
| 13:40:13 | back |

Two full re-enumeration cycles with nothing of ours running. The same handover
to the desk machine is clean every time, so it is this Mac's side — but it is
upstream of anything in this repo, and it is still open.

What the chain *was* is the largest thing this Mac did to a freshly-arrived
card: a capture stream opened within a second of enumeration, a default-input
change, and a kill/restart of sox on every one of those cycles. Removing it
removes this machine's whole contribution to the noise while the real cause is
unresolved. That is the whole argument — not that it was to blame.

**The cost, plainly: there is no noise gate any more.** Meet, Slack and Teams
gate on their own side, which was always the argument for the sidetone carrying
no gate, and is now the argument for there being no gate here at all. OBS and
anything else that wants one has its own.

What it buys beyond the card: nothing here opens the device until an app does,
and that turned out to matter — see below.

## Mute

```bash
micctl mute            # toggle, which is what Option+B runs
micctl mute on|off
micctl mute status
```

Mute sets CoreAudio's mute flag on the **capture side of the card**, and the
reason is not a technicality.

The obvious implementation is the mute flag on the default input — which is now
the card itself, so the flag would sit on the very device every app is holding.
Chrome reads it, and Google Meet answers a deliberate Option+B with *"your
microphone is muted"* over the top of its own mute button. Being told in every
call that the thing you just did on purpose is a fault is worse than the
problem the flag solved.

So the flag goes where the app is not looking. What an app sees is a live,
unmuted device carrying a silent room: nothing to detect, nothing to override.
Measured through a capture that was already open — peak amplitude `0.000639`
live, exactly `0.000000` muted.

`SwitchAudioSource` cannot do this: its `-m` ignores `-s` and only ever acts on
the current default input. That is why `coreaudio-ctl` exists.

The consequence is that **a mute here is invisible to everything except the
lamp and the sidetone.** Nothing will tell you. That is the point, and it is
also why both indicators matter.

## Sidetone

The card's own analog monitoring of the mic back into its output. It is inside
the device and ahead of the ADC, so it has no latency — and for the same reason
it carries **no gate**, and cannot: nothing in the card can gate it. Its mic
DSP is Noise Reduction, AEC, Smart Volume and Mic EQ, all off in firmware on
purpose, and NR is spectral suppression rather than a gate.

A software relay through a virtual device was tried first, carried the gate
properly, and lost on latency and on wedging. It is in the history.

It is a USB-audio-class control, so it is **volatile** — reset on every
re-enumeration — and it is contested: the desk machine switches it *off* when
it takes the card, because it monitors in software there and running both
sidetones at once comb-filters the voice into something thin and echoey. So it
cannot be assumed on either side. Each machine asserts what it wants on
arrival, and here the mute key owns it: muting the host cannot reach an analog
tap that never leaves the card.

## The lamp, and why it is the one gated write

```bash
MIC_RGB_LIVE="255 255 255"
MIC_RGB_MUTED="255 0 0"
```

The lamp is a **vendor HID setting**, not an audio control, and that distinction
runs through the whole module:

> **HID settings persist in the card's firmware. Audio-class settings do not.**

The CrystalVoice fixes and the mic boost carry to any host untouched. The input
source, the sidetone and the mixer volumes reset on every re-enumeration. So the
lamp is the only write here whose effect **outlives the write** — and therefore
the only one that must never land on a card that has not finished arriving.

Two different bars, for two different moments:

| Caller | Bar | Why |
|---|---|---|
| `micctl mute` (Option+B) | attached **and** answering | A keypress has to act. It can happen at any moment, and nothing polls any more, so an isolated check always lands more than `MIC_SETTLE_GAP` after the last one and would restart the settle window — gating the keypress on it would mean the lamp never changed at all. |
| `dockctl` on docking | attached, answering **and** settled for `MIC_SETTLE_SECONDS` | An arrival is exactly the dangerous moment, and dockctl is the only caller that actually watches one: it polls `micctl ready` every five seconds while an assertion is armed, so the window can be satisfied. |

Two things keep the HID traffic down to the edges. `~/.local/state/audio/lamp`
records the colour last painted and a repeat is skipped, because a no-op paint
is still a firmware write. And the record is cleared when the card leaves, since
it comes back carrying whatever the other machine left on it — which is the one
repaint actually needed.

The record is written **before** the attempt, not after a success. Recording
success would mean a CLI that fails gets retried by every caller that comes
along; one attempt per colour per arrival is the whole budget.

The lamp does not read back, so `micctl status` shows `painted` as a record of
the last write rather than a reading. `configured` and `painted` come apart
whenever the card has been away, which is worth being able to see.

`--lighting-rgb` emits only the lighting trio — verified with `--dry-run
--debug`, which showed those three frames and nothing else — so the
CrystalVoice DSP, deliberately off in this card's firmware because it made the
mic sound like a phone, is not disturbed.

## The warm-up gate

A card arriving across a USB switch is **listed by CoreAudio before it will
accept a write**, and writing inside that window is how one docking went wrong:

```
applying: docked
  microphone: could not reach it (could not mute 'Sound BlasterX G6')
```

The dock state changes when the desk **keyboard** appears, because the keyboard
is what tells the Mac it is docked. The card is a separate device behind the
same switch, so the keyboard being up means the card is on its way — never that
it is ready. `micctl` had already resolved the device and the write to it still
failed, so "attached" and "writable" are two states with a gap between them.

`micctl ready` is the gate:

| | |
|---|---|
| attached | CoreAudio lists it as an input at all. |
| answering | it returns its own mute flag. Being listed is not being usable, and that gap is the bug. |
| settled | both have held **at every check** for `MIC_SETTLE_SECONDS`. |

`MIC_SETTLE_SECONDS` is **12**, and the figure comes off the log rather than out
of taste. While the card was cycling it was visible for under three seconds at a
time on a ten-second period, so a window shorter than that period could be
satisfied inside a single appearance of a card that is still restarting — the
one case it exists to catch. The window has to beat the period, not merely feel
generous.

Nothing watches continuously, so "held at every check" also means no two checks
further apart than `MIC_SETTLE_GAP` (15 s). Without that, a stamp left by a
docking an hour ago would read as a settled card the instant this one came back.

The USB tree was considered as a fourth test and left out: `ioreg -p IOUSB` sees
the device node *before* CoreAudio publishes it, so as a gate it is the weaker
of the two signals and adds nothing on top.

`dockctl` **arms** rather than asserts. The transition into docked records that
an assertion is wanted, tries once in case a short undock left the card up, and
otherwise writes nothing; every poll after it asks `micctl ready` and runs
`micctl claim` on the first poll that says yes. The five-second loop is the
retry, so nothing sleeps inside an apply where it would stall the workspace
reconcile that shares it. Observed working through a bad handover:

```
microphone: waiting for the card to settle before asserting it
microphone: unmuted, lamp white, sidetone on (139s after docking)
```

139 seconds of the card cycling, nothing written for any of it, and the
assertion landing on the first poll after it settled. `MIC_APPLY_DEADLINE`
(300 s) stops an armed assertion firing at a baffling moment three hours later.

## Two input settings this deliberately leaves alone

Both are **off by default**, and both were on before BlackHole went. The reason
is the same for each: they existed to work around something the chain itself
caused, and with the chain gone macOS appears to get them right unaided. Rather
than keep a workaround for a problem that may no longer exist, they are
unplugged and the mechanism is left behind one variable each.

### `MIC_ASSERT_INPUT_SOURCE` — the card's physical input

The G6 has four inputs behind one USB interface, exposed as a CoreAudio *data
source*:

```
  Line In
* External Mic      <- the front jack the headset mic plugs into
  S/PDIF In
  What U Hear       <- a loopback of system output, not a microphone
```

It is volatile, and the card comes back from a re-enumeration parked on **Line
In** — a jack with nothing in it — so every app records a flat −90 dBFS and
relays it faithfully. Everything reports healthy, because everything *is*
healthy. It is simply listening to the wrong hole.

This used to have to be **polled**, and that turns out to have been our own
fault. Setting it before the chain opened the device did not survive: CoreAudio
re-asserted its own idea of the source when it configured the device **for
capture** — measured as correct on read-back and back to `Line In` 400 ms later.
With nothing here capturing, the selection holds. Sampled once a second over six
seconds with the chain stopped: `External Mic` throughout.

If an app opening the card for capture ever knocks it back, that is the case
this cannot cover, and `micctl status` flags it:

```
  input source   Line In  [NOT A MIC -- records silence]
```

### `MIC_CLAIM_DEFAULT_INPUT` — which device apps get

macOS re-picks the default input when a device appears, and it used to pick the
card directly — quietly taking the chain and its gate out of the path. Apps
still got a working microphone, just the raw one, so nothing looked wrong until
you were in a meeting. That is what this was for.

With no virtual device competing, the card being picked **is** the wanted
outcome, so there is nothing to correct. Turn it on if macOS starts picking
something else.

## Status

```bash
micctl status
micctl ready        # exit 0 once the card can be written to
micctl claim        # assert what a just-arrived card forgets
```

```
Mute
  state          live
  applied to     Sound BlasterX G6  (capture side, where no app can see it)

Microphone
  device         Sound BlasterX G6
  warm-up        settled 15s ago
  input source   External Mic  (not managed)
  default input  Sound BlasterX G6  (macOS picks this)

Sidetone
  device         on
  wanted         on at 6 dB, following mute
  output         Sound BlasterX G6

Lamp
  configured     live '255 255 255', muted '255 0 0'
  painted        255 255 255
```

## Troubleshooting

| Symptom | Cause |
|---------|-------|
| Apps get silence | Check `input source` in `micctl status`. A card parked on `Line In` records an empty jack, and that is the one failure where every other indicator stays green. |
| An app says your microphone is muted when you muted it deliberately | Not from here: the flag is on the capture side, where no app can read it. Something else set a mute flag on the device the app holds. |
| The lamp did not change on Option+B | The mute still happened — only the lamp is gated. `micctl status` says why under `warm-up`: `not attached` means the card is on the other machine, `not answering` means it is mid-enumeration. It catches up on the next press. |
| The lamp is wrong after docking | `dockctl status` says whether an assertion is still armed and what it is waiting on. A card that never settles is the open hardware problem, not this. |
| `dock-watch.log` says `microphone: gave up after 300s` | The card never arrived — it stayed with the desk machine, or the switch did not hand over. `micctl ready` says which. |
| No sidetone | Volatile, and the desk machine turns it off when it has the card, so after a switch it needs asserting: `micctl mute off`, or just re-dock. |
| Mic indicator always on | No longer expected — nothing here holds the card open. If it is on, an app is holding it. |
| `micctl-coreaudio is missing` | `./install.sh audio`. Needs the Xcode command line tools for `clang`. |
| I want the gate back | It is in the git history, before `refactor(audio): drop the chain`. Note what it costs: a capture stream on the card within a second of every arrival. |

## The desk machine does the same job differently

`omarchy/` has `g6-mic-guard` for the Linux side, and it is worth reading
against this one. PipeWire's generic profile re-asserts `PCM Capture Source` =
Line In every time it configures the card, so over there the input source
genuinely does have to be watched — it polls `alsactl monitor` and puts it back.

The part worth copying is how it paints the lamp: **once, on the absent →
present edge of its own loop**, and that edge is only reachable after
`find_card` has seen the card registered with ALSA. Nothing there can paint a
card mid-arrival, structurally, without any readiness check at all. There is no
poll loop left here to hang that on, so this side checks explicitly instead.

It also holds the card's analog sidetone **off**, because it monitors in
software and two sidetones at once is the comb filter. That is the one setting
the two machines actively disagree about.
