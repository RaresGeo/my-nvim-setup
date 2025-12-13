#!/bin/bash
# Shared package management library for multi-distro dotfiles
# Supports Arch (pacman, yay), Ubuntu (apt, homebrew), and future distros

# Global variables set by parse_install_flags
DISTRO=""
PKG_MANAGER=""

# Color codes for logging
COLOR_GREEN='\e[32m'
COLOR_RED='\e[31m'
COLOR_YELLOW='\e[33m'
COLOR_RESET='\e[0m'

# Logging functions
log() {
    echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
}

error() {
    echo -e "${COLOR_RED}ERROR: $1${COLOR_RESET}" >&2
}

warn() {
    echo -e "${COLOR_YELLOW}WARNING: $1${COLOR_RESET}"
}

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
)

# Package name overrides for distros where names differ
# Format: distro:generic_name=actual_name
# Most packages have same names, so this starts minimal
declare -A PACKAGE_OVERRIDES=(
    # Example: if a distro uses different package names
    # [fedora:somepackage]="different-package-name"
)

# Parse installation flags
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
            *)
                # Unknown option - ignore or could warn
                shift
                ;;
        esac
    done

    # If distro specified but not package manager, use default
    if [[ -n "$DISTRO" && -z "$PKG_MANAGER" ]]; then
        PKG_MANAGER=$(get_default_pkg_manager "$DISTRO")
        if [[ -z "$PKG_MANAGER" ]]; then
            error "Unknown distro: $DISTRO"
            error "Supported distros: arch, ubuntu, debian, fedora, rhel, macos"
            return 1
        fi
        log "Using default package manager for $DISTRO: $PKG_MANAGER"
    fi

    # If package manager specified but not distro, that's okay
    # We'll just use the package manager as-is

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

    if ! command -v "$pkg_mgr" &> /dev/null; then
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

    # Validate inputs
    if [[ -z "$PKG_MANAGER" ]]; then
        log "Skipping package installation (no package manager specified)"
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
