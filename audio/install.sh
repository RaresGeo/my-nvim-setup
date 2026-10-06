#!/bin/bash
# audio module: a gated microphone with sidetone, the macOS equivalent of the
# EasyEffects and VoiceMeeter setups on the other machines.
#
#   - sox, switchaudio-osx and hidapi from Homebrew, plus the BlackHole 2ch driver
#   - micctl into ~/.local/bin
#   - one launchd agent: the processing chain
#
# The Option+B mute hotkey is a Karabiner rule and so lives in that module
# (karabiner/rules/microphone.json), the same way rules/omniwm.json drives the
# omniwm module's CLI. Install both to get the key as well as the chain.
#
# Flags:
#   --no-packages   skip brew (micctl and the agents are still installed)
#   --no-agents     install micctl only, no launchd job
#   --no-monitor    install the chain agent but not the sidetone one
#   --no-default-input  leave the system default input device alone

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! is_macos; then
    error "This module only applies to macOS; nothing to do here."
    exit 1
fi

SINK="BlackHole 2ch"

if (( SKIP_PACKAGES )); then
    log "Skipping packages (--no-packages)."
elif check_pkg_manager_installed brew; then
    log "Installing sox and switchaudio-osx..."
    brew install sox switchaudio-osx
    # hidapi and libusb are for the G6 CLI below, which drives the mute lamp;
    # python@3.13 because the CLI needs 3.12+ and macOS still ships 3.9.
    log "Installing the G6 CLI's dependencies..."
    brew install hidapi libusb python@3.13

    # The driver is a kernel-adjacent install: it needs an admin password and
    # does not exist until the machine has been restarted. Everything else here
    # is happy to be installed before that happens, and micctl waits for the
    # device rather than failing, so a reboot can wait for a convenient moment.
    if SwitchAudioSource -a -t output 2>/dev/null | grep -Fxq "$SINK"; then
        log "$SINK already present."
    else
        log "Installing the $SINK driver (asks for your password)..."
        brew install --cask blackhole-2ch
        warn "$SINK needs a restart before it appears. The chain will wait."
    fi
else
    exit 1
fi

log "Installing micctl..."
link audio/bin/micctl "$HOME/.local/bin/micctl"

# A device with several physical inputs behind one USB interface -- the G6 has
# four -- exposes which one it is listening on as a CoreAudio "data source", and
# that selection is volatile: it resets on every re-enumeration, so a USB switch
# hands the card back parked on Line In with the mic reading an empty jack.
# Nothing in macOS puts it back and no stock CLI can set it, so build the small
# helper that can. Optional: without it micctl still reports the wrong input in
# `status`, it just cannot correct it.
if command -v clang >/dev/null 2>&1; then
    log "Building the CoreAudio helper..."
    mkdir -p "$HOME/.local/libexec"
    if clang -O2 -Wall -framework CoreAudio -framework CoreFoundation \
        -o "$HOME/.local/libexec/micctl-coreaudio" "$MODULE_DIR/src/coreaudio-ctl.c"; then
        log "  -> ~/.local/libexec/micctl-coreaudio"
    else
        warn "CoreAudio helper did not build; micctl can report the input source and"
        warn "sidetone but not correct them."
    fi
else
    warn "clang not found (install the Xcode command line tools), so the CoreAudio"
    warn "helper was not built. micctl can report the input source and sidetone but"
    warn "not correct them."
fi

# The lamp is a vendor HID setting, so it needs the third-party G6 CLI; nothing in
# macOS reaches it. Optional: without it micctl just leaves the lighting alone.
# Pinned to its own venv rather than the system python, which is 3.9 here while the
# CLI needs 3.12+.
G6_VENV="$HOME/.local/share/g6-cli-venv"
if [[ " $* " == *" --no-packages "* ]]; then
    :
elif [[ -x "$G6_VENV/bin/soundblaster-x-g6-cli" ]]; then
    log "G6 CLI already installed."
else
    g6_python=""
    for c in /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 python3.13 python3.12; do
        command -v "$c" >/dev/null 2>&1 && { g6_python="$c"; break; }
    done
    if [[ -z "$g6_python" ]]; then
        warn "No python 3.12+ found, so the G6 CLI was not installed and the mute lamp"
        warn "will not work. brew install python@3.13, then re-run."
    else
        log "Installing the G6 CLI (for the mute lamp)..."
        "$g6_python" -m venv "$G6_VENV" \
            && "$G6_VENV/bin/pip" install --quiet --upgrade pip \
            && "$G6_VENV/bin/pip" install --quiet soundblaster-x-g6-cli \
            && log "  -> $G6_VENV/bin/soundblaster-x-g6-cli" \
            || warn "G6 CLI install failed; the mute lamp will not work."
    fi
fi

mkdir -p "$HOME/.config/audio" "$HOME/.local/state/audio"

# Device names and gate settings are the one genuinely per machine part of
# this, so they live outside the repo, like zsh/local.zsh does. Seed the file
# with the defaults commented out so there is something to edit.
conf="$HOME/.config/audio/local.conf"
if [[ ! -e "$conf" ]]; then
    log "Seeding $conf..."
    cat > "$conf" <<'CONF'
# micctl settings for this machine. Sourced by micctl; not tracked by the repo.
# Defaults are shown commented out. Re-read with: micctl restart

# Pin the hardware mic. This matters: the sink is the system default input, so
# an unpinned chain that followed the default would read its own output.
# MIC_DEVICE="Sound BlasterX G6"

# Used when the default input cannot be read, or has been pointed at the sink:
# MIC_FALLBACK="MacBook Pro Microphone"

# Which physical input the mic device listens on, for a card with several behind
# one USB interface. The selection is volatile -- it resets whenever the device
# re-enumerates, so a USB switch hands a G6 back on "Line In", an empty jack,
# and the mic goes silent. Set this and micctl puts it back on every restart.
# `micctl status` lists what the device offers.
# MIC_INPUT_SOURCE="External Mic"

# The device's own analog mic monitoring -- the sidetone. Volatile, and the desk
# machine turns it off when it takes the card, so micctl asserts it; the mute key
# switches it, because muting the host cannot reach an analog tap inside the card.
# MIC_SIDETONE="on"
# MIC_SIDETONE_DB=6

# The mic's lamp as a mute indicator, "R G B" each 0-255. Needs the G6 CLI.
# MIC_RGB_LIVE="255 255 255"
# MIC_RGB_MUTED="255 0 0"

# Gate threshold in dBFS peak. `micctl levels` measures the room and suggests
# one. Higher cuts more noise but risks clipping quiet speech.
# GATE_THRESHOLD=-45
# GATE_ATTACK=0.02
# GATE_DECAY=0.20
# GATE_DELAY=0
# HIGHPASS_HZ=80

# Makeup gain in dB, applied after the gate. Raise if you come through quiet.
# MIC_GAIN=0

# sox's buffer in bytes, paid once per hop. Clean at 1024 and above on this
# machine; 512 drops data. Raise it if the sidetone crackles.
# SOX_BUFFER=1024

# MIC_NOTIFY=1
CONF
fi

# Make the sink the default input, so a newly installed app needs no setup at
# all. This is only safe once a hardware mic is pinned: an unpinned chain
# follows the default input, and the default input being the sink would wire the
# chain's output back into its own input. So check for the pin rather than
# assume it, because getting this wrong is a feedback loop rather than an error.
if [[ " $* " == *" --no-default-input "* ]]; then
    log "Leaving the default input alone (--no-default-input)."
elif ! SwitchAudioSource -a -t input 2>/dev/null | grep -Fxq "$SINK"; then
    info "$SINK is not available yet; set it as the default input after a restart."
elif ! grep -qE '^[[:space:]]*MIC_DEVICE=' "$conf" 2>/dev/null; then
    warn "Not setting $SINK as the default input: no MIC_DEVICE pinned in"
    warn "$conf. Pin the hardware mic there first, or the chain would read its"
    warn "own output. Then re-run this module."
elif [[ "$(SwitchAudioSource -t input -c 2>/dev/null)" == "$SINK" ]]; then
    log "$SINK is already the default input."
else
    log "Setting $SINK as the default input..."
    SwitchAudioSource -t input -s "$SINK"
fi

if [[ " $* " == *" --no-agents "* ]]; then
    log "Skipping launchd agents (--no-agents)."
else
    agents=(mic-chain)

    # Monitoring used to be a second agent relaying the sink to the headphones.
    # The sidetone is the device's own analog tap now, so that agent is gone --
    # and running both at once comb-filters the voice into something thin and
    # echoey, which is worth actively preventing rather than just not installing.
    if launchctl print "gui/$UID/com.dotfiles.mic-monitor" >/dev/null 2>&1; then
        log "Removing the old monitoring agent..."
        launchctl bootout "gui/$UID/com.dotfiles.mic-monitor" 2>/dev/null || true
    fi
    rm -f "$HOME/Library/LaunchAgents/com.dotfiles.mic-monitor.plist"

    mkdir -p "$HOME/Library/LaunchAgents"
    for name in "${agents[@]}"; do
        log "Installing $name agent..."
        agent="$HOME/Library/LaunchAgents/com.dotfiles.$name.plist"
        sed -e "s|{{ MICCTL }}|$HOME/.local/bin/micctl|g" \
            -e "s|{{ LOGDIR }}|$HOME/.local/state/audio|g" \
            "$MODULE_DIR/com.dotfiles.$name.plist.tpl" > "$agent"
        # bootout first so a re-run picks up a changed plist instead of being a
        # no-op, and so a running sox is replaced rather than duplicated.
        launchctl bootout "gui/$UID/com.dotfiles.$name" 2>/dev/null || true
        launchctl bootstrap "gui/$UID" "$agent"
    done
fi

log "audio installation completed!"
info "$SINK is the default input, so apps need no per-app setup."
info "Check it with: micctl status"
