#!/bin/bash
# Dotfiles installer.
#
# Every directory with an install.sh is a module. This just picks which ones to
# run, in an order that works, and passes your flags through to each of them.
# Running a module's install.sh directly does the same thing.

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
source "$DOTFILES_DIR/lib/os.sh"

# Order matters: zsh and tmux register themed templates that the omarchy module
# regenerates, so omarchy goes last.
MODULE_ORDER=(zsh tmux nvim herdr omarchy)

# Modules that only make sense on an Omarchy host. --all skips these elsewhere;
# naming one explicitly still runs it, and it will tell you why it cannot.
OMARCHY_ONLY=(omarchy herdr)

usage() {
    cat <<USAGE
Usage: install.sh [options] [module...]

Modules:
  zsh       oh-my-zsh, plugins, ~/.zshrc
  tmux      TPM, plugins, ~/.tmux.conf
  nvim      ~/.config/nvim and lazy.nvim plugins
  herdr     ~/.config/herdr/config.toml            (Omarchy only)
  omarchy   Hyprland overrides and theme hooks     (Omarchy only)

Options:
  --all              Install every module applicable to this host
  --list             List modules and exit
  --no-packages      Skip system package installation
  -d, --distro       Override distro detection (arch, ubuntu, debian, fedora, rhel, macos)
  -p, --pkg-manager  Override package manager (pacman, yay, apt, dnf, homebrew)
  -h, --help         Show this help

Module-specific options are passed straight through, e.g.
  ./install.sh herdr --with-claude
  ./install.sh nvim --no-plugins

Examples:
  ./install.sh --all
  ./install.sh nvim tmux
  ./install.sh --all --no-packages
USAGE
}

is_omarchy_only() {
    local module="$1" candidate
    for candidate in "${OMARCHY_ONLY[@]}"; do
        [[ "$candidate" == "$module" ]] && return 0
    done
    return 1
}

module_exists() {
    [[ -x "$DOTFILES_DIR/$1/install.sh" ]]
}

list_modules() {
    local module
    for module in "${MODULE_ORDER[@]}"; do
        module_exists "$module" || continue
        if is_omarchy_only "$module" && ! is_omarchy; then
            echo "  $module (skipped: needs Omarchy)"
        else
            echo "  $module"
        fi
    done
}

run_module() {
    local module="$1"; shift

    if ! module_exists "$module"; then
        error "Unknown module: $module"
        error "Run './install.sh --list' to see what is available."
        return 1
    fi

    echo
    info "==> $module"
    "$DOTFILES_DIR/$module/install.sh" "$@"
}

main() {
    local requested=() passthrough=() install_all=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --list)
                echo "Modules for this host ($(detect_os)$(is_omarchy && echo ", omarchy $(omarchy_version)")):"
                list_modules
                exit 0
                ;;
            --all) install_all=1; shift ;;
            -*)
                # Not ours: hand it to the modules. Two-part flags keep their value.
                case "$1" in
                    -d|--distro|-p|--pkg-manager)
                        passthrough+=("$1" "$2"); shift 2 ;;
                    *)
                        passthrough+=("$1"); shift ;;
                esac
                ;;
            *) requested+=("$1"); shift ;;
        esac
    done

    if (( install_all )); then
        if (( ${#requested[@]} )); then
            error "--all cannot be combined with named modules."
            exit 1
        fi
        local module
        for module in "${MODULE_ORDER[@]}"; do
            module_exists "$module" || continue
            if is_omarchy_only "$module" && ! is_omarchy; then
                warn "Skipping $module (needs Omarchy)."
                continue
            fi
            requested+=("$module")
        done
    fi

    if (( ! ${#requested[@]} )); then
        usage
        exit 1
    fi

    # A leftover checkout at ~/.config/nvim would make the nvim module link the
    # config at itself. Catch it up front rather than partway through a run.
    if [[ "$DOTFILES_DIR" == "$HOME/.config/nvim" ]]; then
        error "This repo is checked out at ~/.config/nvim, which is now a symlink target."
        error "Move it somewhere else first, then re-run:"
        error "  mv ~/.config/nvim ~/.config/dotfiles && ~/.config/dotfiles/install.sh --all"
        exit 1
    fi

    local module
    for module in "${requested[@]}"; do
        run_module "$module" "${passthrough[@]}"
    done

    echo
    log "Done: ${requested[*]}"
}

main "$@"
