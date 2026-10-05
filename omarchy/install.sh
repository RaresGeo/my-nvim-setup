#!/bin/bash
# Omarchy module: the parts of this setup that only make sense on Omarchy.
#
# Everything else in this repo installs on any Linux (or macOS) box. This module
# is the one that does not, so it refuses to run anywhere else rather than
# quietly making a mess.
#
# It covers:
#   - personal Hyprland overrides (hypr/*.lua)
#   - the theme-set hook that hotswaps tmux/zsh/neovim colors
#   - regenerating the themed templates the other modules registered

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! is_omarchy; then
    error "This module only applies to Omarchy hosts; nothing to do here."
    exit 1
fi

if ! check_omarchy_version; then
    error "Omarchy $(omarchy_version) is too old. This repo targets Quattro (${OMARCHY_MIN_MAJOR}.x+),"
    error "which replaced the .conf hyprland config with lua. Run 'omarchy update' first."
    exit 1
fi

# Personal Hyprland overrides. Omarchy's hyprland.lua requires each of these by
# module name after loading its own defaults, so only the files we actually
# diverge on need to be linked -- hyprland.lua itself and the machine-specific
# monitors.lua stay under omarchy's management.
log "Linking Hyprland overrides..."
for config in "$MODULE_DIR"/hypr/*.lua; do
    link "omarchy/hypr/$(basename "$config")" "$HOME/.config/hypr/$(basename "$config")"
done

# Helper scripts. The Sound BlasterX G6 is shared with the MacBook over a USB
# switch, and its capture routing, sidetone and lamp all need asserting on this
# side -- see the comments in bin/g6-mic-guard for why none of it can be assumed.
log "Linking helper scripts..."
mkdir -p "$HOME/.local/bin"
for helper in "$MODULE_DIR"/bin/*; do
    [[ -f "$helper" ]] || continue
    link "omarchy/bin/$(basename "$helper")" "$HOME/.local/bin/$(basename "$helper")"
done

# The guard runs as a user unit: it only needs the mixer and the HID node, both
# of which the desktop user already reaches, so there is nothing here that wants
# root. Linked rather than copied so an edit in the repo takes effect on reload.
log "Installing the G6 guard service..."
mkdir -p "$HOME/.config/systemd/user"
link "omarchy/systemd/g6-mic-guard.service" \
    "$HOME/.config/systemd/user/g6-mic-guard.service"
if command -v systemctl &>/dev/null; then
    systemctl --user daemon-reload
    systemctl --user enable --now g6-mic-guard.service 2>/dev/null \
        || warn "could not enable g6-mic-guard.service"
fi

# Theme hooks. The .d directory is additive, so this sits alongside anything
# else (omarchy's own samples included) without overwriting it.
log "Installing theme-set hooks..."
for hook in "$MODULE_DIR"/hooks/theme-set.d/*; do
    [[ -f "$hook" ]] || continue
    link "omarchy/hooks/theme-set.d/$(basename "$hook")" \
        "$HOME/.config/omarchy/hooks/theme-set.d/$(basename "$hook")"
done

# An earlier version of this repo installed the hook as the flat
# hooks/theme-set file. Drop our own link so the hook does not run twice.
flat_hook="$HOME/.config/omarchy/hooks/theme-set"
if [[ -L "$flat_hook" && "$(readlink -f "$flat_hook")" == "$DOTFILES_DIR"/* ]]; then
    log "Removing superseded flat theme-set hook..."
    rm -f "$flat_hook"
fi

# Regenerate the themed configs the tmux/zsh modules registered templates for.
log "Refreshing omarchy theme to regenerate templated configs..."
omarchy theme refresh || warn "Theme refresh failed; run 'omarchy theme refresh' by hand."

# Validate the Hyprland config rather than finding out at next login.
if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    log "Reloading Hyprland..."
    hyprctl reload >/dev/null
    errors="$(hyprctl configerrors 2>/dev/null)"
    if [[ -n "$errors" && "$errors" != "no errors" ]]; then
        warn "Hyprland reported config errors:"
        echo "$errors"
    fi
else
    log "Hyprland is not running here; overrides apply at next login."
fi

log "Omarchy installation completed!"
