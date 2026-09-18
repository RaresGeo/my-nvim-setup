#!/bin/bash
# Print the state needed to debug this Mac setup in one go. Plain bash 3.2 on
# purpose: it runs before anything else is installed.

section() { printf '\n== %s\n' "$1"; }

section "System"
sw_vers | paste -sd' ' -
sysctl -n machdep.cpu.brand_string

# While an app holds secure input (a focused password field, Terminal's
# "Secure Keyboard Entry", ...), no other app sees keystrokes: every global
# shortcut, AeroSpace's and Karabiner's included, goes dead.
section "Secure input"
pid=$(ioreg -l -w 0 | grep -o '"kCGSSessionSecureInputPID"=[0-9]*' | head -1 | cut -d= -f2)
if [[ -n "$pid" && "$pid" != 0 ]]; then
    echo "ON, held by pid $pid: $(ps -p "$pid" -o comm= 2>/dev/null || echo '(process gone)')"
else
    echo "off"
fi

section "Running"
for app in AeroSpace Alacritty; do
    if pgrep -xq "$app" || pgrep -fq "/$app.app/"; then echo "yes  $app"; else echo "no   $app"; fi
done
if launchctl list 2>/dev/null | grep -qi 'karabiner.console.user.server'; then
    echo "yes  Karabiner"
else
    echo "no   Karabiner"
fi

section "Config links"
for path in ~/.zshrc ~/.tmux.conf ~/.config/nvim ~/.config/alacritty/alacritty.toml \
    ~/.local/state/omarchy/current/theme ~/.config/aerospace/aerospace.toml \
    ~/.config/karabiner/assets/complex_modifications/*.json ~/.local/bin/open-browser; do
    if [[ -L "$path" ]]; then echo "link $path -> $(readlink "$path")"
    elif [[ -e "$path" ]]; then echo "FILE $path (not a link)"
    else echo "---- $path"; fi
done

section "AeroSpace config"
if command -v aerospace >/dev/null; then
    aerospace reload-config --dry-run --no-gui 2>&1 && echo "config OK"
else
    echo "not installed"
fi
