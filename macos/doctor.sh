#!/bin/bash
# Print the state needed to debug this Mac setup in one go. Plain bash 3.2 on
# purpose: it runs before anything else is installed.

section() { printf '\n== %s\n' "$1"; }

section "System"
sw_vers | paste -sd' ' -
sysctl -n machdep.cpu.brand_string

# While an app holds secure input (a focused password field, Terminal's
# "Secure Keyboard Entry", ...), no other app sees keystrokes: every global
# shortcut, OmniWM's and Karabiner's included, goes dead.
section "Secure input"
pid=$(ioreg -l -w 0 | grep -o '"kCGSSessionSecureInputPID"=[0-9]*' | head -1 | cut -d= -f2)
if [[ -n "$pid" && "$pid" != 0 ]]; then
    echo "ON, held by pid $pid: $(ps -p "$pid" -o comm= 2>/dev/null || echo '(process gone)')"
else
    echo "off"
fi

section "Running"
for app in OmniWM Alacritty; do
    if pgrep -xq "$app" || pgrep -fq "/$app.app/"; then echo "yes  $app"; else echo "no   $app"; fi
done
if launchctl list 2>/dev/null | grep -qi 'karabiner.console.user.server'; then
    echo "yes  Karabiner"
else
    echo "no   Karabiner"
fi
if launchctl list 2>/dev/null | grep -q 'com.danielsetup.omniwm-empty-workspace-focus'; then
    echo "yes  omniwm-empty-workspace-focus"
else
    echo "no   omniwm-empty-workspace-focus"
fi
if launchctl list 2>/dev/null | grep -q 'com.dotfiles.dock-watch'; then
    echo "yes  dock-watch"
else
    echo "no   dock-watch"
fi

section "Config links"
for path in ~/.zshrc ~/.tmux.conf ~/.config/nvim ~/.config/alacritty/alacritty.toml \
    ~/.local/state/omarchy/current/theme ~/.config/omniwm/settings.toml \
    ~/.local/bin/omniwm-empty-workspace-focus ~/.local/bin/dockctl \
    ~/.config/karabiner/assets/complex_modifications/*.json \
    ~/.local/bin/open-browser ~/.local/bin/dismiss-notification; do
    if [[ -L "$path" ]]; then echo "link $path -> $(readlink "$path")"
    elif [[ -e "$path" ]]; then echo "FILE $path (not a link)"
    else echo "---- $path"; fi
done

# The font size and Zen scale follow the dock state, so a terminal that came
# back the wrong size is usually a stale state file rather than a config bug.
section "Dock"
# ~/.local/bin is not on PATH in a non-interactive shell, so resolve the link
# the installer made rather than trusting `command -v`.
dockctl="$(command -v dockctl || echo "$HOME/.local/bin/dockctl")"
if [[ -x "$dockctl" ]]; then
    "$dockctl" status
else
    echo "dockctl not installed"
fi

section "OmniWM"
if command -v omniwmctl >/dev/null; then
    omniwmctl ping 2>&1 && echo "IPC OK" || echo "IPC not responding"
else
    echo "not installed"
fi
