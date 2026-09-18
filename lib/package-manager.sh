#!/bin/bash
# Cross-distro package installation for the module install scripts.
#
# Logging and path helpers live in common.sh; this file only knows about
# package managers and package groups.

LIB_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=lib/os.sh
source "$LIB_DIR/os.sh"

# Set by parse_install_flags. DISTRO is auto-detected when not passed.
DISTRO=""
PKG_MANAGER=""
SKIP_PACKAGES=0

# Package manager update commands
declare -A PKG_MANAGER_UPDATE=(
    [pacman]="sudo pacman -Sy"
    [yay]="yay -Sy"
    [apt]="sudo apt update"
    [homebrew]="brew update"
    [dnf]="sudo dnf check-update || true"  # dnf returns 100 if updates available
)

# Package manager install commands
declare -A PKG_MANAGER_INSTALL=(
    [pacman]="sudo pacman -S --noconfirm --needed"
    [yay]="yay -S --noconfirm --needed"
    [apt]="sudo apt install -y"
    [homebrew]="brew install"
    [dnf]="sudo dnf install -y"
)

# Default package manager for each distro
declare -A DISTRO_DEFAULT_PKG_MANAGER=(
    [arch]="pacman"
    [ubuntu]="apt"
    [debian]="apt"
    [fedora]="dnf"
    [rhel]="dnf"
    [macos]="homebrew"
)

# Package groups - abstract package requirements
declare -A PACKAGE_GROUPS=(
    [zsh_essentials]="zsh curl git"
    [tmux_essentials]="tmux git"
    [nvim_essentials]="neovim git curl unzip ripgrep fd"
    [herdr_essentials]="herdr"
)

# Package name overrides for distros where names differ
# Format: distro:generic_name=actual_name
# Most packages have same names, so this starts minimal
declare -A PACKAGE_OVERRIDES=(
    # Debian and Ubuntu ship fd under a different binary/package name because
    # "fd" was already taken.
    [ubuntu:fd]="fd-find"
    [debian:fd]="fd-find"
)

# Parse installation flags.
#
# Distro and package manager are auto-detected from the host, so the common
# case is passing nothing at all. The flags stay as an override for cross-distro
# testing or for preferring yay over pacman.
parse_install_flags() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --distro|-d)
                DISTRO="$2"
                shift 2
                ;;
            --pkg-manager|-p)
                PKG_MANAGER="$2"
                shift 2
                ;;
            --no-packages)
                SKIP_PACKAGES=1
                shift
                ;;
            *)
                # Modules define their own extra flags; ignore what we do not own.
                shift
                ;;
        esac
    done

    if (( SKIP_PACKAGES )); then
        return 0
    fi

    # Auto-detect the distro when it was not given.
    if [[ -z "$DISTRO" ]]; then
        DISTRO="$(detect_os)"
        if [[ -z "$DISTRO" ]]; then
            warn "Could not detect this distro; package installation will be skipped."
            warn "Pass --distro <distro> --pkg-manager <manager> to install packages anyway."
            SKIP_PACKAGES=1
            return 0
        fi
        log "Detected distro: $DISTRO"
    fi

    # If distro specified but not package manager, use default
    if [[ -z "$PKG_MANAGER" ]]; then
        PKG_MANAGER=$(get_default_pkg_manager "$DISTRO")
        if [[ -z "$PKG_MANAGER" ]]; then
            error "Unknown distro: $DISTRO"
            error "Supported distros: arch, ubuntu, debian, fedora, rhel, macos"
            return 1
        fi
        log "Using default package manager for $DISTRO: $PKG_MANAGER"
    fi

    return 0
}

# Get default package manager for a distro
get_default_pkg_manager() {
    local distro="$1"
    echo "${DISTRO_DEFAULT_PKG_MANAGER[$distro]}"
}

# Check if package manager is installed
check_pkg_manager_installed() {
    local pkg_mgr="$1"
    local binary="$pkg_mgr"

    # The homebrew package manager is invoked as brew.
    [[ "$pkg_mgr" == "homebrew" ]] && binary="brew"

    if ! command -v "$binary" &> /dev/null; then
        error "Package manager '$pkg_mgr' is not installed"

        # Provide helpful installation instructions
        case "$pkg_mgr" in
            yay)
                error "Install yay with: git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
                ;;
            homebrew|brew)
                error "Install Homebrew from: https://brew.sh"
                ;;
            *)
                error "Please install '$pkg_mgr' before running this script"
                ;;
        esac
        return 1
    fi

    return 0
}

# Map generic package name to distro-specific name
map_package_name() {
    local package="$1"
    local override_key="${DISTRO}:${package}"

    # Check if there's a distro-specific override
    if [[ -n "${PACKAGE_OVERRIDES[$override_key]}" ]]; then
        echo "${PACKAGE_OVERRIDES[$override_key]}"
    else
        # No override, use original name
        echo "$package"
    fi
}

# Map all packages in a list
map_package_names() {
    local packages="$1"
    local mapped=""

    for pkg in $packages; do
        local mapped_pkg=$(map_package_name "$pkg")
        mapped="$mapped $mapped_pkg"
    done

    # Trim leading space
    echo "$mapped" | xargs
}

# Install packages using the specified package manager
install_packages() {
    local package_group="$1"

    if (( SKIP_PACKAGES )); then
        log "Skipping package installation (--no-packages)"
        return 0
    fi

    if [[ -z "$PKG_MANAGER" ]]; then
        log "Skipping package installation (no package manager available)"
        return 0
    fi

    # Check if package group exists
    if [[ -z "${PACKAGE_GROUPS[$package_group]}" ]]; then
        error "Unknown package group: $package_group"
        return 1
    fi

    # Get packages for this group
    local packages="${PACKAGE_GROUPS[$package_group]}"

    # Map to distro-specific names if needed
    if [[ -n "$DISTRO" ]]; then
        packages=$(map_package_names "$packages")
    fi

    log "Installing packages with $PKG_MANAGER: $packages"

    # Check if package manager is installed
    if ! check_pkg_manager_installed "$PKG_MANAGER"; then
        return 1
    fi

    # Get update and install commands
    local update_cmd="${PKG_MANAGER_UPDATE[$PKG_MANAGER]}"
    local install_cmd="${PKG_MANAGER_INSTALL[$PKG_MANAGER]}"

    if [[ -z "$update_cmd" || -z "$install_cmd" ]]; then
        error "Package manager '$PKG_MANAGER' is not supported"
        error "Supported package managers: pacman, yay, apt, homebrew, dnf"
        return 1
    fi

    # Update package lists
    log "Updating package lists..."
    if ! eval "$update_cmd"; then
        warn "Failed to update package lists, continuing anyway..."
    fi

    # Install packages
    log "Installing packages..."
    if ! eval "$install_cmd $packages"; then
        error "Failed to install packages: $packages"
        return 1
    fi

    log "Successfully installed packages: $packages"
    return 0
}
