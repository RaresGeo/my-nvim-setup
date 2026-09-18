#!/bin/bash
# Build Alacritty from source into ~/Applications.
#
# Homebrew disabled the Alacritty cask on 2026-09-01 because the upstream
# release is not signed or notarized. A local build is not quarantined, so
# Gatekeeper lets it run. (Some managed Macs block unsigned binaries no matter
# where they came from.)
#
# Usage: macos/build-alacritty.sh [git-ref]   (default: latest release tag)

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

if ! xcode-select -p &>/dev/null; then
    error "Xcode command line tools are missing. Run: xcode-select --install"
    exit 1
fi

# rustup's installer puts cargo in ~/.cargo/bin without touching this shell.
# shellcheck source=/dev/null
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

if ! command -v cargo &>/dev/null; then
    error "Rust is missing. Install it with rustup's official installer:"
    error "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    exit 1
fi

SRC="$HOME/.local/src/alacritty"

if [[ -d "$SRC/.git" ]]; then
    log "Updating Alacritty source..."
    git -C "$SRC" fetch --tags --quiet
else
    log "Cloning Alacritty..."
    git clone --quiet https://github.com/alacritty/alacritty.git "$SRC"
fi

ref="${1:-$(git -C "$SRC" tag --list 'v*' --sort=-version:refname | grep -v -- '-' | head -1)}"
log "Building Alacritty $ref..."
git -C "$SRC" checkout --quiet "$ref"
make -C "$SRC" app

mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Alacritty.app"
cp -R "$SRC/target/release/osx/Alacritty.app" "$HOME/Applications/"

# So scripts and the shell can call `alacritty msg ...` directly.
mkdir -p "$HOME/.local/bin"
ln -sfn "$HOME/Applications/Alacritty.app/Contents/MacOS/alacritty" "$HOME/.local/bin/alacritty"

log "Alacritty $ref installed to ~/Applications/Alacritty.app"
