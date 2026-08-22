#!/bin/bash
# Herdr module: wire up the herdr config. Herdr ships with Omarchy, so this
# only links config -- it never installs the binary.

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! command -v herdr &>/dev/null; then
    error "herdr not found. It ships with Omarchy; install it before running this."
    exit 1
fi

log "Setting up herdr config symlink..."
link herdr/config.toml "$HOME/.config/herdr/config.toml"

# Validate before anything tries to load it
log "Validating herdr config..."
herdr config check

# Agent state integration. This writes hooks into ~/.claude/settings.json so
# herdr can tell whether Claude is working, blocked, or done -- opt in, since it
# edits a config outside this repo.
if [[ " $* " == *" --with-claude "* ]]; then
    log "Installing herdr <-> Claude Code integration..."
    herdr integration install claude
else
    log "Skipping Claude Code integration (it edits ~/.claude/settings.json)."
    log "Run with --with-claude to enable agent status, or: herdr integration install claude"
fi

# Reload a running server so the new config takes effect without a restart
if [[ $(herdr status server --json 2>/dev/null | jq -r '.running' 2>/dev/null) == "true" ]]; then
    log "Reloading running herdr server..."
    herdr server reload-config >/dev/null
fi

log "Herdr installation completed!"
log "Start it with 'herdr'. Prefix is CTRL+A, matching tmux. Press PREFIX + ? for keybindings."
