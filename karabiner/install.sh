#!/bin/bash
# Karabiner module: key remaps and launcher shortcuts (macOS only).
#
#   - builtin-keyboard.json: swaps fn and left Ctrl on the MacBook's own
#     keyboard, so Ctrl sits in the corner. External keyboards are untouched.
#   - rules/*.json: complex modifications (Option+Enter terminal, Option+Shift+B
#     browser, Option+, to dismiss a notification), also linked into
#     Karabiner's assets for its UI.
#
# Karabiner owns karabiner.json, so this merges into the selected profile
# instead of replacing it: our device entry and rules are swapped in by
# identifier/description, everything else is kept, and the old file is backed
# up whenever something changes. Rules we installed before are tracked in
# .dotfiles-rules.json so that renaming or deleting one here removes the old
# copy too. Edit the files here, not Karabiner's UI.

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
link karabiner/bin/dismiss-notification "$HOME/.local/bin/dismiss-notification"

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

# Rules are matched by description, so renaming one here used to leave the old
# copy behind in the profile for ever -- and a leftover rule still fires, which
# makes it a shortcut that nothing in the repo explains. This manifest records
# what we installed last time: a description in it that we no longer ship is
# ours to remove. Rules added by hand in Karabiner's UI are not in it and are
# left alone.
manifest = os.path.expanduser("~/.config/karabiner/.dotfiles-rules.json")
try:
    with open(manifest) as f:
        owned = set(json.load(f))
except (OSError, ValueError):
    owned = set()

ours = []
for rule_file in sorted(glob.glob(os.path.join(module, "rules", "*.json"))):
    with open(rule_file) as f:
        ours.extend(json.load(f)["rules"])
descriptions = [rule["description"] for rule in ours]

rules = profile.setdefault("complex_modifications", {}).setdefault("rules", [])
for stale in sorted(owned - set(descriptions)):
    if any(r.get("description") == stale for r in rules):
        print("  dropping stale rule: " + stale)
rules[:] = [r for r in rules if r.get("description") not in owned | set(descriptions)] + ours

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

os.makedirs(os.path.dirname(manifest), exist_ok=True)
with open(manifest, "w") as f:
    json.dump(descriptions, f, indent=4)
PY

log "Karabiner installation completed!"
info "First run only: open Karabiner-Elements and approve its driver and Input Monitoring."
