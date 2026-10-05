#!/bin/bash
# audio module: a gated microphone with sidetone, the macOS equivalent of the
# EasyEffects and VoiceMeeter setups on the other machines.
#
#   - sox and switchaudio-osx from Homebrew, plus the BlackHole 2ch driver
#   - micctl into ~/.local/bin
#   - two launchd agents: the processing chain, and monitoring
#
# The Option+B mute hotkey is a Karabiner rule and so lives in that module
# (karabiner/rules/microphone.json), the same way rules/omniwm.json drives the
# omniwm module's CLI. Install both to get the key as well as the chain.
#
# Flags:
#   --no-packages   skip brew (micctl and the agents are still installed)
#   --no-agents     install micctl only, no launchd jobs
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

# Pin the monitoring output instead of following the system default output:
# MONITOR_DEVICE="External Headphones"
# MONITOR_GAIN=0

# Monitoring refuses to run on the built-in speakers, because that is an
# acoustic feedback loop. Set to 1 only if you know the mic cannot hear them.
# MONITOR_ALLOW_SPEAKERS=0

# Monitoring only runs while docked, because undocked there is no headset to
# hear it in. Set to 0 to monitor anywhere the output allows it.
# MONITOR_REQUIRE_DOCK=1

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
    if [[ " $* " == *" --no-monitor "* ]]; then
        log "Skipping the monitoring agent (--no-monitor)."
    else
        agents+=(mic-monitor)
    fi

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
