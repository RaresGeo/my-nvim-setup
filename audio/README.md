# audio

A gated microphone with sidetone on macOS: the job EasyEffects does on the
Linux boxes and VoiceMeeter Potato does on Windows.

```bash
./install.sh audio
```

macOS has no equivalent of either. It cannot route a mic into an output at all,
and it has no insert point where a gate could sit, so this builds one out of a
virtual audio device and two SoX pipelines.

```
                    ┌─────────────── micctl chain ───────────────┐
built-in mic  ──────│  remix ─ → highpass 80Hz → noise gate      │─────┐
(or any input)      └────────────────────────────────────────────┘      │
                                                                        ▼
                                                               ┌─────────────────┐
                              Teams, browser, anything  ◀───────│  BlackHole 2ch  │
                              (their input device)              └─────────────────┘
                                                                        │
```

Hearing yourself does not come through any of that: it is the card's own analog
tap, inside the device and ahead of the ADC, so it has no latency and no gate.
See [The sidetone](#the-sidetone).

| File | Does |
|------|------|
| `bin/micctl` | The whole thing: `mute`, `sidetone`, `status`, `levels`, `start`/`stop`/`restart`, and the resident `chain` job. |
| `com.dotfiles.mic-chain.plist.tpl` | launchd agent for the processing chain. Rendered by `install.sh`, which bakes in the absolute paths launchd needs. |
| `src/coreaudio-ctl.c` | Reads and sets the input source and the sidetone. macOS shows both in System Settings but ships no CLI for either. Built by `install.sh`. |
| `~/.config/audio/local.conf` | Device names and gate settings for this machine. Seeded by `install.sh`, not tracked: it is the only per-host part. |

The **Option+B** mute key is a Karabiner rule, so it lives in that module
(`karabiner/rules/microphone.json`) the way `rules/omniwm.json` drives the
omniwm module's CLI. Install both modules to get the key as well as the chain.

## No per-app setup

**BlackHole 2ch is the system default input**, so an app picks the gate up with
no configuration at all, including an app installed next year. Nothing has to be
set per app.

That only works because the chain does **not** follow the default input. It
reads a pinned hardware device:

```bash
MIC_DEVICE="Sound BlasterX G6"          # ~/.config/audio/local.conf
MIC_FALLBACK="MacBook Pro Microphone"
```

Without the pin, "follow the default input" plus "the default input is the sink"
is a feedback loop: the chain reads its own output. `resolve_mic` refuses to
follow the default when it resolves to the sink for that reason.

**The pin is checked for presence, not trusted.** This desk's mic is behind a
USB switch and vanishes whenever the switch hands it to the other machine, so a
pin that was taken at face value would leave the chain dead half the time.
Instead the supervisor re-resolves every couple of seconds and restarts sox when
the answer changes, and apps never notice because the device *they* hold is the
sink, which never goes away. Nothing has to be re-selected anywhere:

| `MIC_DEVICE` | Resolves to |
|---|---|
| pinned, present | the pinned device |
| pinned, unplugged | `MIC_FALLBACK` (the built-in mic) |
| unpinned, default input is the sink | `MIC_FALLBACK`, refusing the loop |
| pinned to anything else present | that device |

Because apps read BlackHole, **the chain is a single point of failure for your
microphone**: if it is not running, apps get silence rather than raw mic. That is
why both agents are `RunAtLoad` and `KeepAlive`, and why `micctl status` leads
with whether they are actually alive.

## Mute

**Option+B** does three things, in this order:

| | |
|---|---|
| 1. mute flag | CoreAudio's own per-device flag, via `SwitchAudioSource -t input -m toggle`, on the default input — which here is the sink, so it silences exactly what every app reads. |
| 2. sidetone | switched off when muting, on when unmuting. Necessary, not cosmetic: the sidetone is an analog tap inside the card, so muting the host cannot reach it and you would otherwise still hear yourself while muted. |
| 3. lamp | the G6's logo goes red when muted, white when live. |

The order matters. Muting switches the sidetone off *before* repainting the lamp,
so you stop hearing yourself immediately; unmuting switches it on *after*, so the
lamp is never white while you are still inaudible.

Measured at **157–164 ms** end to end, including the HID write for the lamp. It
all runs inline rather than backgrounded: a backgrounded lamp write could land
behind a second keypress and leave the colour contradicting the state.

The lamp is why `micctl` needs the third-party G6 CLI; the lighting is a vendor
HID setting and nothing in macOS reaches it. It is deliberately scoped to
`--lighting-rgb`, since the same CLI can reach the CrystalVoice DSP that is
switched **off** in this device's firmware on purpose. Verified with
`--dry-run --debug`: that flag emits the three lighting frames, three times, and
nothing else.

Both are opt-in, because they are specific to a device that has them:

```bash
MIC_SIDETONE="on"                  # local.conf
MIC_SIDETONE_DB=6
MIC_RGB_LIVE="255 255 255"
MIC_RGB_MUTED="255 0 0"
```

A real mute flag beats setting the volume to zero: there is no level to remember
on the way back, and it does not fight with whatever you have the input gain set
to. Verified on the sink with an injected tone: −23 dBFS unmuted, −96 dBFS
muted.

Two honest limitations:

- **The flag cannot be read back** from the shell, so `micctl status` reports
  the last state set here rather than CoreAudio's. The hotkey uses
  SwitchAudioSource's own `toggle`, so the device always flips even if that
  record has drifted; `micctl mute on` and `off` are absolute.
- **The hardware mic stays live.** An app pointed directly at the G6 rather
  than at the sink would still hear you. Nothing here can reach that:
  `SwitchAudioSource`'s `-m` ignores `-s` and only ever acts on the current
  default input.

There is deliberately no sound or notification on toggle — the lamp is the
indicator, and it is visible without taking focus or making noise.

### What Option+B costs

Karabiner intercepts at the HID level, so Option+B never reaches the focused
app, and Alacritty has `option_as_alt = "Both"`:

- **Alt+B is gone in the shell.** It was `backward-word`. The same command is
  still on **Ctrl+Left** (`^[[1;5D`), which is reachable on the built-in
  keyboard because `devices/builtin-keyboard.json` puts Ctrl in the corner.
- **Option+Shift+B was already gone**, claimed by the browser rule in
  `karabiner/rules/launchers.json`, so `^[B` → `backward-word` was lost before
  this module existed.
- Option+B no longer types **∫**.

Nothing else in the stack wants it: nvim has no `<M-b>`, tmux has no Alt
bindings, `herdr/config.toml` uses Alt only with Enter, Esc, the digits and the
arrows, and OmniWM's roster has no Option+B.

## The gate

It is an **expander**, not a gate, and that distinction is the whole reason it
sounds like a room rather than a switch.

SoX has no `gate` effect, and `sox(1)`'s `compand` documentation offers one:
map everything below the threshold to `-inf`. That was the first version here
and it was wrong. It measures perfectly — tones at −60 through −44 dBFS came out
as digital silence, −40 and above untouched to within 0.01 dB — and it sounds
uncanny, because absolute silence alternating with room tone makes the ear
track the switching instead of ignoring the noise. Every real-world gate, in
EasyEffects or VoiceMeeter, attenuates by a finite amount along a sloped curve.

So the transfer function has three points: a floor where attenuation has
levelled off, the bottom of a transition window, and unity at the threshold.
The segment below the window runs parallel to unity, which is what holds the
attenuation constant down there instead of letting it run away to silence.

```
compand 0.02,0.35 6:-90,-115,-52,-77,-40,-40 0 -90 0
```

Measured, with the defaults:

| Input | Output | Change |
|-------|--------|--------|
| −75 … −60 dBFS | floor | **−25 dB**, constant |
| −55 | −82.6 | −24.6 dB |
| −50 | −74.2 | −21.2 dB |
| −46 | −63.2 | −14.2 dB |
| −43 | −54.0 | −8.0 dB |
| −40 | −46.5 | −3.5 dB |
| −37 | −41.2 | −1.1 dB |
| −33 and above | unchanged | **0.0 dB** |

Nothing is ever switched off, and speech is bit-for-bit untouched. The ramp is
continuous across 12 dB with a 6 dB knee rounding both corners.

**The threshold is peak, not RMS**, because the expander acts on the envelope.
That is why `micctl levels` reports window peaks.

| Setting | Default | |
|---------|---------|-|
| `GATE_THRESHOLD` | `-40` | dBFS peak where the curve reaches unity. |
| `GATE_RANGE` | `25` | How far down quiet material is pushed, in dB. This is the knob for "too much noise" vs "sounds gated"; it is not infinite on purpose. |
| `GATE_WIDTH` | `12` | dB over which the ramp runs. Wider is smoother and lets more noise through near the top. |
| `GATE_KNEE` | `6` | Rounds both corners so the ends of the ramp are not audible as events. |
| `GATE_ATTACK` | `0.02` | Fast, so a word's first consonant survives. |
| `GATE_DECAY` | `0.35` | Slow, so it eases out across the gaps between words rather than chattering. |
| `GATE_DELAY` | `0` | A predictive window costs its own length in latency and, measured, buys nothing: `0.02` and `0` gate identically and a burst keeps its onset to within 0.01 dB. |
| `MIC_GAIN` | `0` | Makeup gain in dB, applied **after** the gate, so a threshold from `micctl levels` stays correct whatever the gain is. |
| `GATE_RANGE=inf` | — | Restores the `sox(1)` hard gate. Kept because it is what the manual documents, not because it sounds good. |

### Tuning it

```bash
micctl levels          # sit still for five seconds
```

It takes the peak of each 0.25 s window and reports the median, p90 and max,
then suggests p90 + 10 dB. Ten rather than five because the threshold is where
the curve reaches *unity* and the ramp runs `GATE_WIDTH` below it, so the floor
wants to sit inside that ramp rather than right at the top of it. The whole-recording peak is useless here: a single
keyboard clack, or the mute confirmation sound leaking back in through the
speakers, sets it 30 dB too high. That happened while this was being written,
which is why the percentile is there.

The desk mic (Sound BlasterX G6) measures window peaks with a median of −55.4
and a p90 of −49.6 dBFS. Unity at −40 therefore puts the room floor around 20 dB
down while leaving speech untouched.

## The sidetone

Hearing yourself is the **card's own analog monitoring** — `playthru` in
CoreAudio's terms, which macOS shows under System Settings > Sound. The signal is
tapped inside the G6 ahead of the ADC and mixed straight back into the headphone
output, so it never reaches the host at all.

```bash
MIC_SIDETONE="on"       # local.conf
MIC_SIDETONE_DB=6
```

Two consequences, both load-bearing:

**Zero latency.** Nothing buffers it, because nothing in software touches it.

**It carries no gate.** The tap is ahead of everything the host does, so what you
hear is the raw mic, not what Meet or Slack receive. If the gate ever clamps your
speech, the sidetone will not tell you. That is an accepted trade here rather than
an oversight: Meet and Slack both gate on their own side, and the gate below is
set loose enough to only take out static, so the far end hearing *less* than the
sidetone is the unlikely direction. The deciding factor was that zero latency
beat hearing the gate.

**So mute has to switch it explicitly.** Muting the host cannot reach a signal
that never leaves the card — `micctl mute` therefore switches the sidetone and
repaints the lamp as well as setting the mute flag. See [Mute](#mute).

### It resets, and the other machine wants the opposite

`playthru` is a USB-audio-class control, which means volatile: the device resets
it on every re-enumeration, and handing the card across the USB switch is a
re-enumeration. On top of that the desk machine wants it **off** — it monitors
through a PipeWire loopback so it can hear its EasyEffects gate, and running both
at once comb-filters the voice into something thin and echoey.

So neither machine may assume anything about it, and both assert what they want
when the card arrives:

| | asserts | where |
|---|---|---|
| This Mac | sidetone **on**, lamp white, mic unmuted | `dockctl` on the transition into docked |
| Desk machine | sidetone **off**, lamp white | `g6-mic-guard` on the absent→present edge |

`dockctl` only does it on the *transition*, not every poll — asserting it on a
five-second timer would fight the mute key and unmute you a moment after you
pressed it.

### A software relay was tried first, and lost

Monitoring used to be a second sox pipeline reading the sink and writing to the
headphones, which did carry the gate. It is in the history if the trade ever needs
revisiting, along with why it was dropped:

* **It wedged.** sox stays alive when CoreAudio reconfigures under it, relays
  nothing, and floods `unhandled buffer overrun. Data discarded.` at ~28KB/s.
  Measured against the card's own `What U Hear` loopback: a tone reached the
  output at −12 dBFS played directly, −12 dBFS through a fresh relay, and
  **−90.31 dBFS** through one that had been up 23 minutes. It also ignored
  SIGTERM and needed SIGKILL, so the supervisor's own restart could not clear it.
* **Latency**, which is the thing the analog tap gets right for free.
* The stall detector that came out of it is still in `supervise`, because the
  chain can wedge the same way. A working pipeline logs zero overruns, so the
  threshold is not delicate.


## The input source resets itself

A card with several physical inputs behind one USB interface exposes which one it
is listening on as a CoreAudio *data source* — macOS shows it under System
Settings > Sound > Input. The G6 has four:

```
  Line In
* External Mic      <- the front jack the PC38X mic plugs into
  S/PDIF In
  What U Hear       <- a loopback of system output, not a microphone
```

That selection is a **USB-audio-class control, so it is volatile**: it resets to
the device's default on every re-enumeration. Handing the card to another machine
over the USB switch and taking it back is a re-enumeration, and it comes back on
**Line In** — a jack with nothing in it. The chain then records a flat −90 dBFS,
one bit, and relays it faithfully. Everything reports healthy, because everything
*is* healthy: the device is attached, unmuted, at volume, the agents are up. It
is simply listening to the wrong hole.

The Linux side has the same problem for a different reason — PipeWire's generic
profile re-asserts `PCM Capture Source` = Line In every time it configures the
card — and solves it with a guard that watches mixer events (`g6-mic-guard`).

Here, `MIC_INPUT_SOURCE` in `local.conf` does it:

```bash
MIC_INPUT_SOURCE="External Mic"
```

The chain supervisor re-asserts it whenever it has drifted, and `micctl status`
shows what the device is on, flags a source that cannot carry a mic, and lists
the alternatives:

```
  mic            Sound BlasterX G6
  input source   Line In  [NOT A MIC -- records silence]  (pinned to 'External Mic')
                 * Line In
                   External Mic
                   ...
```

It has to be **polled, not set once at startup**. Setting it before the chain
opens the device does not survive: CoreAudio re-asserts its own idea of the
source when it configures the device for capture. Measured — the write returns
`noErr`, reads back correct, and is `Line In` again 400 ms later. Asserted from
the poll loop once sox is up it holds, and the change reaches the running
capture, so sox does not need restarting around it.

macOS ships no CLI that can set a data source (`SwitchAudioSource` does devices
and the mute flag, `system_profiler` can only read it), so `install.sh` builds
`src/input-source.c` to `~/.local/libexec/micctl-input-source` — one clang call,
two system frameworks, no third-party dependency. Without it `status` still
reports the wrong input, it just cannot correct it.

**The CrystalVoice fixes are not affected by any of this.** Those are HID
settings and they persist in the device's own firmware, so they carry to any
host — see `~/personal/sound-blasterx-g6-linux.md` on the desk machine. Only the
audio-class controls (source selection, mixer volumes, sidetone) are volatile.

## Troubleshooting

```bash
micctl status                                   # devices, gate, agent health
tail -f ~/.local/state/audio/mic-chain.log      # the chain says why it is waiting
```

| Symptom | Cause |
|---------|-------|
| Apps get silence | The chain is not running, or BlackHole is installed but the machine has not been restarted. `micctl status` says which. |
| Chain log says "waiting: BlackHole 2ch is not installed" | Restart the machine, or the cask never installed. |
| No sidetone | `micctl status` prints it under `Sidetone / device`. It is volatile and the desk machine turns it off, so after a USB switch it needs asserting: `micctl sidetone on`, or just re-dock. |
| Mic indicator always on | Expected: the chain holds the mic open permanently. That is the cost of a gate that applies to outgoing audio. |
| Log fills with sox's usage text and `missing filename` | sox format options (`-r`, `-c`) must come *before* the device they describe. Put them after and sox reads the device as the output, then finds options with no file left. The supervisor backs off on immediate failures so the real error stays readable. |
| Sink is silent while the mic clearly works | Expected when nobody is talking: that is the gate holding shut. Measure with `micctl levels`, or speak while capturing. |
| Chain runs but everything is silent | sox may be missing Microphone permission under launchd, which is a different responsible process from your terminal. Check System Settings → Privacy & Security → Microphone. |
| Gate cuts off quiet speech | Lower `GATE_THRESHOLD`, or widen `GATE_WIDTH`. |
| It sounds like a gate switching on and off | Reduce `GATE_RANGE` (less attenuation), widen `GATE_WIDTH`, or raise `GATE_DECAY`. Check `GATE_RANGE` is not set to `inf`. |
| Too much background still audible | Raise `GATE_RANGE`, or raise `GATE_THRESHOLD` so more of the floor falls inside the ramp. |
