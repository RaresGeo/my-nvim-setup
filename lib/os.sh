#!/bin/bash
# Host detection: which OS are we on, and is this an Omarchy machine?
#
# The point of splitting this out is that modules can ask "is this Omarchy?"
# instead of assuming it. Everything Omarchy-specific lives behind is_omarchy,
# so the same module installs cleanly on a plain Arch box, Ubuntu, or macOS --
# it just does less.

[[ -n "${DOTFILES_OS_SOURCED:-}" ]] && return 0
DOTFILES_OS_SOURCED=1

# Minimum Omarchy major version this repo targets. Quattro (4.x) replaced the
# .conf-based hyprland config with lua and moved the omarchy tree to
# /usr/share/omarchy, so nothing here works against 3.x or earlier.
OMARCHY_MIN_MAJOR=4

# Print a normalized distro id: arch, ubuntu, debian, fedora, rhel, macos.
# Empty when the host is something we have no package mapping for.
detect_os() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "macos"
        return 0
    fi

    [[ -r /etc/os-release ]] || return 0

    local ID="" ID_LIKE=""
    # shellcheck source=/dev/null
    . /etc/os-release

    case "$ID" in
        arch|archarm|manjaro|endeavouros|cachyos) echo "arch"; return 0 ;;
        ubuntu|pop|linuxmint|elementary)          echo "ubuntu"; return 0 ;;
        debian|raspbian)                          echo "debian"; return 0 ;;
        fedora)                                   echo "fedora"; return 0 ;;
        rhel|centos|rocky|almalinux)              echo "rhel"; return 0 ;;
    esac

    # Fall back to the ID_LIKE chain for derivatives we do not name above.
    case " $ID_LIKE " in
        *" arch "*)   echo "arch" ;;
        *" ubuntu "*) echo "ubuntu" ;;
        *" debian "*) echo "debian" ;;
        *" fedora "*) echo "fedora" ;;
        *" rhel "*)   echo "rhel" ;;
    esac
}

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# True when this host is running Omarchy.
is_omarchy() {
    [[ -d /usr/share/omarchy ]] && command -v omarchy &>/dev/null
}

# Major.minor.patch of the installed Omarchy, or empty.
omarchy_version() {
    is_omarchy || return 0
    omarchy version 2>/dev/null | head -1 | grep -oE '^[0-9]+(\.[0-9]+)*'
}

# True when Omarchy is present and new enough for the configs in this repo.
is_omarchy_quattro() {
    local version major
    version="$(omarchy_version)"
    [[ -n "$version" ]] || return 1
    major="${version%%.*}"
    (( major >= OMARCHY_MIN_MAJOR ))
}

# Warn once when we are on an Omarchy too old to support. Callers still decide
# whether to continue -- most modules degrade to "not Omarchy" and carry on.
check_omarchy_version() {
    is_omarchy || return 1

    if ! is_omarchy_quattro; then
        warn "Omarchy $(omarchy_version) predates Quattro (${OMARCHY_MIN_MAJOR}.x)."
        warn "Omarchy integration is skipped; upgrade with 'omarchy update' to enable it."
        return 1
    fi

    return 0
}

# Decide whether a named integration applies to this host. run_integration
# consults this before sourcing a module's <name>.sh, so an Omarchy-only step
# simply does not run on a plain Arch, Ubuntu, or macOS box.
integration_supported() {
    case "$1" in
        omarchy) check_omarchy_version ;;
        *)       return 0 ;;
    esac
}
