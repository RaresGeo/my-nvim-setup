#!/bin/bash
# Make one keyboard layout the only one enabled, and select it.
#
# This Mac is a British machine -- its internal keyboard reports
# KeyboardLanguage "British" -- so macOS picked com.apple.keylayout.British at
# setup, which puts £ on Shift+3, " on Shift+2 and @ on Shift+'. Everything
# else in this repo assumes the US positions, so declare them here.
#
# Why not `defaults write com.apple.HIToolbox`: the enabled and selected
# sources do live in that domain, but the running input system holds them in
# memory and writes the domain back out itself, so a write from outside is
# ignored until the next login and then usually overwritten. Text Input
# Services is the supported way in, hence the C helper below. `cc` comes with
# the Xcode command line tools, which this module already requires for
# build-alacritty.sh.
#
# Only keyboard *layouts* are touched. The non-keyboard input methods in the
# same list -- the character palette and Dictation -- are left alone, because
# disabling those takes away the emoji picker rather than a layout.
#
# Usage: macos/keyboard-layout.sh [input-source-id]
#   e.g. macos/keyboard-layout.sh com.apple.keylayout.British   # to go back

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

LAYOUT="${1:-com.apple.keylayout.US}"

if ! command -v cc &>/dev/null; then
    error "cc is missing, so the keyboard layout cannot be set from here."
    error "Install the Xcode command line tools (xcode-select --install), or set"
    error "it by hand: System Settings > Keyboard > Input Sources > Edit."
    exit 1
fi

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

cat > "$build/select-layout.c" <<'C'
// Select a keyboard layout by input source id and disable every other layout.
#include <Carbon/Carbon.h>
#include <stdio.h>
#include <string.h>

static int source_id(TISInputSourceRef source, char *out, size_t len) {
    CFStringRef id = (CFStringRef)TISGetInputSourceProperty(source, kTISPropertyInputSourceID);
    return id && CFStringGetCString(id, out, (CFIndex)len, kCFStringEncodingUTF8);
}

static int is_layout(TISInputSourceRef source) {
    CFStringRef type = (CFStringRef)TISGetInputSourceProperty(source, kTISPropertyInputSourceType);
    return type && CFStringCompare(type, kTISTypeKeyboardLayout, 0) == kCFCompareEqualTo;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <input-source-id>\n", argv[0]);
        return 2;
    }
    const char *wanted = argv[1];
    char id[256];

    // true: include layouts that are installed but not enabled yet, which the
    // one being asked for usually is.
    CFArrayRef installed = TISCreateInputSourceList(NULL, true);
    if (!installed) {
        fprintf(stderr, "cannot read the input source list\n");
        return 1;
    }

    TISInputSourceRef target = NULL;
    for (CFIndex i = 0; i < CFArrayGetCount(installed); i++) {
        TISInputSourceRef source = (TISInputSourceRef)CFArrayGetValueAtIndex(installed, i);
        if (source_id(source, id, sizeof id) && strcmp(id, wanted) == 0) {
            target = source;
            break;
        }
    }
    if (!target) {
        fprintf(stderr, "no input source called %s is installed\n", wanted);
        return 1;
    }

    // Enabling first: selecting a source that is not enabled fails with paramErr.
    OSStatus status = TISEnableInputSource(target);
    if (status != noErr) {
        fprintf(stderr, "could not enable %s (OSStatus %d)\n", wanted, (int)status);
        return 1;
    }
    status = TISSelectInputSource(target);
    if (status != noErr) {
        fprintf(stderr, "could not select %s (OSStatus %d)\n", wanted, (int)status);
        return 1;
    }
    printf("selected %s\n", wanted);

    // Now that the wanted layout is the live one, the others can go: leaving a
    // second layout enabled puts a flag in the menu bar and a switch key the
    // old layout can come back through.
    CFArrayRef enabled = TISCreateInputSourceList(NULL, false);
    if (enabled) {
        for (CFIndex i = 0; i < CFArrayGetCount(enabled); i++) {
            TISInputSourceRef source = (TISInputSourceRef)CFArrayGetValueAtIndex(enabled, i);
            if (!is_layout(source)) continue;
            if (!source_id(source, id, sizeof id) || strcmp(id, wanted) == 0) continue;
            if (TISDisableInputSource(source) == noErr) printf("disabled %s\n", id);
            else fprintf(stderr, "could not disable %s\n", id);
        }
        CFRelease(enabled);
    }
    CFRelease(installed);
    return 0;
}
C

cc -O2 -framework Carbon -o "$build/select-layout" "$build/select-layout.c"

log "Setting the keyboard layout to $LAYOUT..."
# Not a pipe: a pipeline's failure would not trip `set -e` here.
applied="$("$build/select-layout" "$LAYOUT")"
while IFS= read -r line; do log "  $line"; done <<< "$applied"
