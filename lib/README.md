# Shared Libraries

Three files, sourced by the module install scripts.

| File | Responsibility |
|------|----------------|
| `common.sh` | Repo root resolution, logging, symlinking, module bootstrapping |
| `os.sh` | Distro detection and Omarchy detection |
| `package-manager.sh` | Cross-distro package installation |

Sourcing `package-manager.sh` pulls in the other two, so a module only needs the
one line.

## common.sh

Sets `DOTFILES_DIR` to the repo root, resolved from `common.sh`'s own location
through any symlinks. That is what lets the checkout live anywhere.

| Function | Purpose |
|----------|---------|
| `module_init "${BASH_SOURCE[0]}"` | Sets `MODULE_DIR` and `MODULE_NAME` |
| `link <repo-path> <dest>` | Symlink `$DOTFILES_DIR/<repo-path>` to `<dest>`, creating parents and backing up anything real already there |
| `backup_path <path>` | Move a real file/directory to `<path>.bak.<timestamp>`; existing symlinks are left alone so re-runs stay idempotent |
| `run_integration <name>` | Source `$MODULE_DIR/<name>.sh` if it exists and the host supports it |
| `log` / `info` / `warn` / `error` | Colored output; `error` goes to stderr |

## os.sh

| Function | Returns |
|----------|---------|
| `detect_os` | `arch`, `ubuntu`, `debian`, `fedora`, `rhel`, `macos`, or empty |
| `is_omarchy` | True when Omarchy is installed |
| `omarchy_version` | e.g. `4.0.0` |
| `is_omarchy_quattro` | True when the major version is at least `OMARCHY_MIN_MAJOR` (4) |
| `check_omarchy_version` | Same, but warns on an Omarchy too old to support |
| `integration_supported <name>` | Consulted by `run_integration`; gates `omarchy` on `check_omarchy_version` |

`detect_os` reads `ID` from `/etc/os-release` and falls back to the `ID_LIKE`
chain, so derivatives (EndeavourOS, Pop!\_OS, Linux Mint, Rocky, ...) resolve to
their base.

Omarchy support is pinned to Quattro (4.x). Earlier versions configured Hyprland
through `.conf` files and kept the omarchy tree in `~/.local/share/omarchy`;
none of the configs here apply to them.

## package-manager.sh

### Usage

```bash
#!/bin/bash
set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"
install_packages "zsh_essentials"
```

`parse_install_flags` detects the distro and picks its default package manager,
so no flags are needed in the common case. It ignores flags it does not
recognise, which is how modules take their own options (`--with-claude`,
`--no-plugins`) from the same argument list.

### Flags

```bash
./install.sh                                   # auto-detect
./install.sh --no-packages                     # config only, no packages
./install.sh --distro ubuntu                   # override detection, default manager
./install.sh --distro arch --pkg-manager yay   # override both
./install.sh -d arch -p yay                    # short forms
```

### Supported combinations

| Distribution | Default | Alternatives |
|--------------|---------|--------------|
| Arch | `pacman` | `yay` |
| Ubuntu | `apt` | `homebrew` |
| Debian | `apt` | `homebrew` |
| Fedora | `dnf` | `homebrew` |
| RHEL | `dnf` | — |
| macOS | `homebrew` | — |

## Extending

### A new package group

Groups are abstract requirement lists, named `<module>_essentials` by
convention:

```bash
declare -A PACKAGE_GROUPS=(
    [zsh_essentials]="zsh curl git"
    [mymodule_essentials]="foo bar"
)
```

### A new distribution

Add its default package manager:

```bash
declare -A DISTRO_DEFAULT_PKG_MANAGER=(
    [mydistro]="mypm"
)
```

Add it to `detect_os` in `os.sh` if `/etc/os-release` needs mapping, and add
update/install commands if the package manager is new:

```bash
declare -A PKG_MANAGER_UPDATE=(
    [mypm]="sudo mypm update"
)

declare -A PKG_MANAGER_INSTALL=(
    [mypm]="sudo mypm install -y"
)
```

### A package with a different name

Most package names match across distros. Only the exceptions need an entry,
keyed `distro:generic`:

```bash
declare -A PACKAGE_OVERRIDES=(
    [ubuntu:fd]="fd-find"
    [debian:fd]="fd-find"
)
```
