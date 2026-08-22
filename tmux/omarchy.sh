#!/bin/bash
# Omarchy integration for the tmux module. Sourced by tmux/install.sh via
# run_integration, which only fires on an Omarchy Quattro host.

# Omarchy ships its own ~/.config/tmux/tmux.conf. tmux loads that *after*
# ~/.tmux.conf, so it silently overrides everything here -- prefix, bindings,
# theme, and continuum's auto-save hook. Drop it so this config wins; running
# 'omarchy refresh tmux' puts it back if it's ever wanted.
if [ -f ~/.config/tmux/tmux.conf ]; then
    log "Removing omarchy's ~/.config/tmux/tmux.conf (it would override ~/.tmux.conf)..."
    rm -f ~/.config/tmux/tmux.conf
fi

# Register the themed template so 'omarchy theme set' regenerates the tmux
# colors from the active palette.
log "Registering tmux theme template with omarchy..."
link tmux/tmux.conf.tpl "$HOME/.config/omarchy/themed/tmux.conf.tpl"
