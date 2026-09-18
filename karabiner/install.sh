#!/bin/bash
# Karabiner module: key remaps and launcher shortcuts (macOS only).
#
#   - builtin-keyboard.json: swaps fn and left Ctrl on the MacBook's own
#     keyboard, so Ctrl sits in the corner. External keyboards are untouched.
#   - rules/*.json: complex modifications (Cmd+Enter terminal, Cmd+Shift+B
#     browser), also linked into Karabiner's assets for its UI.
#
# Karabiner owns karabiner.json, so this merges into the selected profile
# instead of replacing it: our device entry and rules are swapped in by
# identifier/description, everything else is kept, and the old file is backed
# up whenever something changes. Edit the files here, not Karabiner's UI.

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! is_macos; then
    error "This module only applies to macOS; nothing to do here."
    exit 1
fi

if (( ! SKIP_PACKAGES )) && [[ ! -d /Applications/Karabiner-Elements.app ]]; then
    log "Installing Karabiner-Elements..."
    brew install --cask karabiner-elements
fi

log "Linking rules and helpers..."
for rule in "$MODULE_DIR"/rules/*.json; do
    link "karabiner/rules/$(basename "$rule")" \
        "$HOME/.config/karabiner/assets/complex_modifications/$(basename "$rule")"
done
link karabiner/bin/open-browser "$HOME/.local/bin/open-browser"

log "Merging into karabiner.json..."
/usr/bin/python3 - "$MODULE_DIR" <<'PY'
import glob, json, os, shutil, sys, time

module = sys.argv[1]
path = os.path.expanduser("~/.config/karabiner/karabiner.json")

if os.path.exists(path):
    with open(path) as f:
        original = f.read()
    config = json.loads(original)
else:
    original = None
    config = {"profiles": [{"name": "Default profile", "selected": True}]}

profiles = config.setdefault("profiles", [])
profile = next((p for p in profiles if p.get("selected")), profiles[0])

with open(os.path.join(module, "builtin-keyboard.json")) as f:
    device = json.load(f)
devices = [d for d in profile.get("devices", []) if d.get("identifiers") != device["identifiers"]]
profile["devices"] = devices + [device]

rules = profile.setdefault("complex_modifications", {}).setdefault("rules", [])
for rule_file in sorted(glob.glob(os.path.join(module, "rules", "*.json"))):
    with open(rule_file) as f:
        for rule in json.load(f)["rules"]:
            rules[:] = [r for r in rules if r.get("description") != rule["description"]]
            rules.append(rule)

updated = json.dumps(config, indent=4) + "\n"
if updated == original:
    print("  karabiner.json already up to date")
else:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if original is not None:
        backup = path + ".bak." + time.strftime("%Y%m%d%H%M%S")
        shutil.copy(path, backup)
        print("  backed up to " + backup)
    with open(path, "w") as f:
        f.write(updated)
    print("  updated " + path)
PY

log "Karabiner installation completed!"
info "First run only: open Karabiner-Elements and approve its driver and Input Monitoring."
