#!/bin/bash
# Shared helpers for every module install script.
#
# Sourcing this sets DOTFILES_DIR to the repo root, resolved from this file's
# own location, so the repo works from anywhere on disk -- ~/.config/dotfiles,
# ~/dotfiles, a checkout in /tmp -- with no path baked into any script.

# Guard against double-sourcing (module scripts and the top-level installer
# both pull this in).
[[ -n "${DOTFILES_COMMON_SOURCED:-}" ]] && return 0
DOTFILES_COMMON_SOURCED=1

# Resolve the repo root through any symlinks in the path to this file.
_common_source="${BASH_SOURCE[0]}"
while [[ -L "$_common_source" ]]; do
    _common_dir="$(cd -P "$(dirname "$_common_source")" && pwd)"
    _common_source="$(readlink "$_common_source")"
    [[ "$_common_source" != /* ]] && _common_source="$_common_dir/$_common_source"
done
DOTFILES_DIR="$(cd -P "$(dirname "$_common_source")/.." && pwd)"
unset _common_source _common_dir
export DOTFILES_DIR

# Color codes for logging
COLOR_GREEN='\e[32m'
COLOR_RED='\e[31m'
COLOR_YELLOW='\e[33m'
COLOR_BLUE='\e[34m'
COLOR_RESET='\e[0m'

log() {
    echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
}

error() {
    echo -e "${COLOR_RED}ERROR: $1${COLOR_RESET}" >&2
}

warn() {
    echo -e "${COLOR_YELLOW}WARNING: $1${COLOR_RESET}"
}

info() {
    echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
}

# Move an existing file or directory out of the way before symlinking over it.
# Symlinks are not backed up -- re-running an install should be idempotent, not
# leave a trail of backups of its own previous runs.
backup_path() {
    local target="$1"

    [[ -e "$target" || -L "$target" ]] || return 0
    [[ -L "$target" ]] && return 0

    local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    warn "$target exists and is not a symlink; moving it to $backup"
    mv "$target" "$backup"
}

# link <path-relative-to-repo-root> <destination>
#
# Creates destination's parent, backs up anything real already sitting there,
# then points the destination at the repo. -n keeps an existing directory
# symlink from swallowing the new link inside itself.
link() {
    local src="$DOTFILES_DIR/$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        error "cannot link missing source: $src"
        return 1
    fi

    mkdir -p "$(dirname "$dest")"
    backup_path "$dest"
    ln -sfn "$src" "$dest"
    log "  linked $dest -> $src"
}

# Run a module's optional integration script, e.g. `run_integration omarchy`
# from within a module directory. Missing scripts are not an error -- that is
# how a module says "nothing special to do here". Nor is an unsupported host:
# integration_supported (defined in os.sh) decides whether the target platform
# is actually present, which is what keeps these modules installable off
# Omarchy.
run_integration() {
    local name="$1"
    local dir="${2:-$MODULE_DIR}"
    local script="$dir/${name}.sh"

    [[ -f "$script" ]] || return 0

    if declare -f integration_supported &>/dev/null; then
        integration_supported "$name" || {
            log "Skipping $name integration (not applicable on this host)."
            return 0
        }
    fi

    info "Running $name integration for $(basename "$dir")..."
    # shellcheck source=/dev/null
    source "$script"
}

# Every module script starts the same way: know where you are, know where the
# repo is. Call as: module_init "${BASH_SOURCE[0]}"
module_init() {
    MODULE_DIR="$(cd -P "$(dirname "$1")" && pwd)"
    MODULE_NAME="$(basename "$MODULE_DIR")"
    export MODULE_DIR MODULE_NAME
}
