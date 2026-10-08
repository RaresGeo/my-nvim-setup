#!/bin/bash
# audio module: mute, sidetone and the mute lamp for the desk microphone on
# macOS. Apps talk to the sound card directly -- there is no virtual device and
# no processing chain.
#
#   - switchaudio-osx from Homebrew, plus hidapi/libusb/python for the G6 CLI
#   - micctl into ~/.local/bin
#   - the CoreAudio helper into ~/.local/libexec
#   - no launchd agent, and nothing resident at all
#
# This module used to install sox, the BlackHole 2ch driver and a launchd agent
# running a gated capture chain, with BlackHole as the system default input so
# every app got the gate with no per-app setup. That is in the git history.
#
# It went because the card kept re-enumerating on arrival at this Mac, and
# although the chain was measured NOT to be the cause -- the cycling reproduces
# with every agent booted out -- the chain was the largest thing this machine
# did to a freshly-arrived card. Removing it removes this machine's whole
# contribution while the real cause is still open. The cost is that there is no
# noise gate any more; Meet, Slack and Teams gate on their own side, and OBS
# has its own.
#
# An install that finds the old chain still running boots it out and removes
# its agent, so switching to this version needs nothing by hand. The BlackHole
# driver is deliberately NOT uninstalled -- it needs an admin password and a
# restart, and leaving an unused driver installed harms nothing. `brew uninstall
# --cask blackhole-2ch` when convenient.
#
# The Option+B mute hotkey is a Karabiner rule and so lives in that module
# (karabiner/rules/microphone.json), the same way rules/omniwm.json drives the
# omniwm module's CLI. Install both to get the key as well as the CLI.
#
# Flags:
#   --no-packages   skip brew (micctl and the helper are still installed)

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! is_macos; then
    error "This module only applies to macOS; nothing to do here."
    exit 1
fi

if (( SKIP_PACKAGES )); then
    log "Skipping packages (--no-packages)."
elif check_pkg_manager_installed brew; then
    log "Installing switchaudio-osx..."
    brew install switchaudio-osx
    # hidapi and libusb are for the G6 CLI below, which drives the mute lamp;
    # python@3.13 because the CLI needs 3.12+ and macOS still ships 3.9.
    log "Installing the G6 CLI's dependencies..."
    brew install hidapi libusb python@3.13
else
    exit 1
fi

log "Installing micctl..."
link audio/bin/micctl "$HOME/.local/bin/micctl"

# A device with several physical inputs behind one USB interface -- the G6 has
# four -- exposes which one it is listening on as a CoreAudio "data source", and
# macOS ships no CLI that can set one. The same helper carries the capture-side
# mute flag and the sidetone, neither of which SwitchAudioSource can reach on a
# device by name. Without it micctl can report the input source and sidetone but
# not correct them, and the mute key does not work at all.
if command -v clang >/dev/null 2>&1; then
    log "Building the CoreAudio helper..."
    mkdir -p "$HOME/.local/libexec"
    if clang -O2 -Wall -framework CoreAudio -framework CoreFoundation \
        -o "$HOME/.local/libexec/micctl-coreaudio" "$MODULE_DIR/src/coreaudio-ctl.c"; then
        log "  -> ~/.local/libexec/micctl-coreaudio"
    else
        warn "CoreAudio helper did not build, so Option+B will not work."
    fi
else
    warn "clang not found (install the Xcode command line tools), so the CoreAudio"
    warn "helper was not built and Option+B will not work."
fi

# The lamp is a vendor HID setting, so it needs the third-party G6 CLI; nothing
# in macOS reaches it. Optional: without it micctl just leaves the lighting
# alone. Pinned to its own venv rather than the system python, which is 3.9 here
# while the CLI needs 3.12+.
G6_VENV="$HOME/.local/share/g6-cli-venv"
if (( SKIP_PACKAGES )); then
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

# Device names are the one genuinely per-machine part of this, so they live
# outside the repo, like zsh/local.zsh does. Seed the file with the defaults
# commented out so there is something to edit.
conf="$HOME/.config/audio/local.conf"
if [[ ! -e "$conf" ]]; then
    log "Seeding $conf..."
    cat > "$conf" <<'CONF'
# micctl settings for this machine. Sourced by micctl; not tracked by the repo.
# Defaults are shown commented out. Nothing is resident, so a change takes
# effect on the next micctl run -- which for Option+B is the next keypress.

# The card. Left empty, micctl follows whatever macOS calls the default input,
# which is right for a laptop with only a built-in mic.
# MIC_DEVICE="Sound BlasterX G6"

# Used when the card is not attached -- undocked, or handed to another machine.
# MIC_FALLBACK="MacBook Pro Microphone"

# The card's own analog mic monitoring -- the sidetone. Volatile, and the desk
# machine turns it off when it takes the card, so micctl asserts it; the mute key
# switches it, because muting the host cannot reach an analog tap inside the card.
# MIC_SIDETONE="on"
# MIC_SIDETONE_DB=6

# The card's lamp as a mute indicator, "R G B" each 0-255. Needs the G6 CLI.
# This is the only setting here written over HID rather than CoreAudio, which
# means it persists in the card's firmware -- so micctl refuses to write it to a
# card that has not finished arriving. See audio/README.md.
# MIC_RGB_LIVE="255 255 255"
# MIC_RGB_MUTED="255 0 0"

# Two input settings micctl deliberately leaves alone, both off by default.
# Each existed to work around something the old capture chain caused, and with
# the chain gone macOS appears to get them right unaided. Turn one on if it
# stops doing so; `micctl status` reports what it sees either way.
#
# Put the card's physical input back when it drifts. The G6 comes back from a
# re-enumeration parked on "Line In", an empty jack, so apps record silence --
# but that was CoreAudio reacting to OUR capture, and with nothing capturing the
# selection holds.
# MIC_ASSERT_INPUT_SOURCE=1
# MIC_INPUT_SOURCE="External Mic"
#
# Make the card the system default input on arrival. macOS re-picks the default
# when a device appears and now picks the card, which is the wanted outcome.
# MIC_CLAIM_DEFAULT_INPUT=1
CONF
fi

# Switching from the chain version: boot the old agent out and take its plist
# with it, so the capture stream it held is released and a reboot does not bring
# it back. Done unconditionally rather than behind a flag -- leaving a resident
# sox holding the card is the exact thing this version exists to stop.
for name in mic-chain mic-monitor; do
    if launchctl print "gui/$UID/com.dotfiles.$name" >/dev/null 2>&1; then
        log "Removing the old $name agent..."
        launchctl bootout "gui/$UID/com.dotfiles.$name" 2>/dev/null || true
    fi
    rm -f "$HOME/Library/LaunchAgents/com.dotfiles.$name.plist"
done

log "audio installation completed!"
info "Nothing runs in the background. Apps select the card directly."
info "Check it with: micctl status"
