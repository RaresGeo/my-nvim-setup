#!/bin/bash
# Omarchy integration for the zsh module. Sourced by zsh/install.sh via
# run_integration, which only fires on an Omarchy Quattro host.

# Register the themed template so 'omarchy theme set' regenerates the agnoster
# segment colors from the active palette. .zshrc sources the generated file and
# reloads it on SIGUSR1, which the theme-set hook sends.
log "Registering zsh color template with omarchy..."
link zsh/zsh-colors.tpl "$HOME/.config/omarchy/themed/zsh-colors.tpl"
