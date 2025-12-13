# Package Manager Library

This library provides cross-distribution package management for the dotfiles installation scripts.

## Overview

The `package-manager.sh` library abstracts package installation across different Linux distributions and package managers. It allows installation scripts to work on Arch, Ubuntu, Fedora, and other distros without modification.

## Usage

### In Installation Scripts

Source the library and use its functions:

```bash
#!/bin/bash
set -e

# Source the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/package-manager.sh"

# Parse flags
parse_install_flags "$@"

# Install packages
if [[ -n "$DISTRO" || -n "$PKG_MANAGER" ]]; then
    install_packages "zsh_essentials"
fi
```

### Command Line Flags

Users run installation scripts with flags to specify their environment:

```bash
# Specify both distro and package manager
./install.sh --distro arch --pkg-manager pacman
./install.sh --distro ubuntu --pkg-manager apt

# Short flags
./install.sh -d arch -p yay

# Just distro (uses default package manager)
./install.sh --distro ubuntu  # Uses apt

# No flags (skips package installation)
./install.sh
```

## Supported Distros and Package Managers

| Distribution | Default Package Manager | Alternative Managers |
|--------------|------------------------|---------------------|
| Arch Linux   | `pacman`               | `yay`              |
| Ubuntu       | `apt`                  | `homebrew`         |
| Debian       | `apt`                  | `homebrew`         |
| Fedora       | `dnf`                  | `homebrew`         |
| RHEL         | `dnf`                  | -                  |
| macOS        | `homebrew`             | -                  |

## Adding a New Distribution

To add support for a new distribution:

### 1. Add Default Package Manager

Edit `lib/package-manager.sh` and add to the `DISTRO_DEFAULT_PKG_MANAGER` array:

```bash
declare -A DISTRO_DEFAULT_PKG_MANAGER=(
    [arch]="pacman"
    [ubuntu]="apt"
    [mynewdistro]="mypackagemanager"  # Add this line
)
```

### 2. Add Package Manager Commands (if new)

If the distribution uses a package manager not already supported, add update and install commands:

```bash
declare -A PKG_MANAGER_UPDATE=(
    [pacman]="sudo pacman -Sy"
    [apt]="sudo apt update"
    [mypackagemanager]="sudo mypm update"  # Add this
)

declare -A PKG_MANAGER_INSTALL=(
    [pacman]="sudo pacman -S --noconfirm --needed"
    [apt]="sudo apt install -y"
    [mypackagemanager]="sudo mypm install -y"  # Add this
)
```

### 3. Add Package Name Overrides (if needed)

Most packages have the same name across distributions. Only add overrides if package names differ:

```bash
declare -A PACKAGE_OVERRIDES=(
    [mynewdistro:git]="git-scm"  # If 'git' is called 'git-scm' on your distro
)
```

### 4. Test

```bash
./zsh/install.sh --distro mynewdistro --pkg-manager mypackagemanager
./tmux/install.sh --distro mynewdistro --pkg-manager mypackagemanager
```

## Adding a New Package Group

Package groups define sets of packages that installation scripts need. To add a new group:

```bash
declare -A PACKAGE_GROUPS=(
    [zsh_essentials]="zsh curl git"
    [tmux_essentials]="tmux git"
    [neovim_essentials]="neovim gcc make"  # Add this
)
```

Then use it in your installation script:

```bash
install_packages "neovim_essentials"
```

## Package Name Overrides

When a package has a different name on a specific distribution, add an override:

```bash
declare -A PACKAGE_OVERRIDES=(
    # Format: [distro:generic_name]="actual_name"
    [fedora:curl]="curl-minimal"
    [macos:tmux]="tmux"  # Usually same, but can override
)
```

The library will automatically use the override when installing on that distro.

## API Reference

### Functions

#### `parse_install_flags "$@"`
Parses command line flags and sets global variables `DISTRO` and `PKG_MANAGER`.

**Flags:**
- `--distro <name>` or `-d <name>`: Set distribution
- `--pkg-manager <name>` or `-p <name>`: Set package manager

**Example:**
```bash
parse_install_flags "$@"
```

#### `install_packages <package_group>`
Installs a group of packages using the configured package manager.

**Arguments:**
- `package_group`: Name of the package group (e.g., "zsh_essentials")

**Returns:**
- `0` on success
- `1` on failure

**Example:**
```bash
install_packages "zsh_essentials"
```

#### `get_default_pkg_manager <distro>`
Returns the default package manager for a distribution.

**Arguments:**
- `distro`: Distribution name

**Example:**
```bash
PKG_MGR=$(get_default_pkg_manager "arch")  # Returns "pacman"
```

#### `check_pkg_manager_installed <pkg_manager>`
Checks if a package manager is installed and provides helpful error messages.

**Arguments:**
- `pkg_manager`: Package manager name

**Returns:**
- `0` if installed
- `1` if not found

#### `log <message>`
Prints a success/info message in green.

#### `error <message>`
Prints an error message in red to stderr.

#### `warn <message>`
Prints a warning message in yellow.

## Troubleshooting

### Package Manager Not Found

**Error:**
```
ERROR: Package manager 'yay' is not installed
```

**Solution:**
Install the package manager or use an alternative:

```bash
# For yay on Arch
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Or use pacman instead
./install.sh --distro arch --pkg-manager pacman
```

### Package Not Available

**Error:**
```
ERROR: Failed to install packages: somepackage
```

**Solution:**
- Verify the package name is correct for your distribution
- Add a package name override if the package has a different name
- Check if the package requires a different package manager (e.g., AUR packages need `yay`)

### Unknown Distro

**Error:**
```
ERROR: Unknown distro: mydistro
```

**Solution:**
Add your distribution to the library (see "Adding a New Distribution" above).

### Invalid Combination

If you specify a package manager that doesn't make sense for your distro (e.g., `--distro arch --pkg-manager apt`), the library will still attempt to use it. Ensure you're using compatible combinations.

## Design Philosophy

1. **Explicit over implicit**: Users specify their environment rather than auto-detection
2. **Backwards compatible**: No flags = no package installation (skip gracefully)
3. **Fail-fast with helpful errors**: Check package manager availability upfront
4. **DRY principle**: Single source of truth for package management
5. **Easy to extend**: Adding a distro should take minutes, not hours

## Examples

### Arch Linux with pacman
```bash
./zsh/install.sh --distro arch --pkg-manager pacman
```

### Arch Linux with yay (AUR)
```bash
./zsh/install.sh --distro arch --pkg-manager yay
```

### Ubuntu with apt
```bash
./zsh/install.sh --distro ubuntu --pkg-manager apt
```

### Ubuntu with Homebrew
```bash
./zsh/install.sh --distro ubuntu --pkg-manager homebrew
```

### Using defaults (just distro)
```bash
./zsh/install.sh --distro arch  # Uses pacman
./zsh/install.sh --distro ubuntu  # Uses apt
```

### Skip package installation
```bash
./zsh/install.sh  # No flags, installs only Oh My Zsh and configs
```
