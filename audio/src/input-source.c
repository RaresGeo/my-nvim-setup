// input-source -- read and set a CoreAudio device's INPUT data source.
//
// macOS shows this as "Input Source" under System Settings > Sound > Input, for
// devices that have more than one physical input behind one USB interface. The
// Sound BlasterX G6 has four (Line In, External Mic, S/PDIF In, What U Hear)
// and the selection is a USB-audio-class control, which means it is VOLATILE:
// it resets to the device's default on every re-enumeration. Unplugging the G6,
// or handing it to another machine over a USB switch and taking it back, brings
// it up on Line In -- an empty jack -- and the microphone is then digital
// silence with nothing in the OS to say why.
//
// There is no stock CLI for it. SwitchAudioSource sets the default device and
// the mute flag but does not touch the data source, and system_profiler can
// only read it. So this exists to let micctl put the selection back.
//
// Built by ../install.sh. No third-party dependencies -- just clang and the two
// system frameworks.
//
//   input-source get  <device>
//   input-source list <device>            '*' marks the current one
//   input-source set  <device> <substring>
#include <CoreAudio/CoreAudio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const AudioObjectPropertyAddress kSources = {
    kAudioDevicePropertyDataSources, kAudioObjectPropertyScopeInput, kAudioObjectPropertyElementMain };
static const AudioObjectPropertyAddress kCurrent = {
    kAudioDevicePropertyDataSource, kAudioObjectPropertyScopeInput, kAudioObjectPropertyElementMain };

// The name of one source id. It is an AudioValueTranslation, not a plain get:
// the id goes in and a CFString comes back.
static int name_of(AudioObjectID dev, UInt32 sid, char *out, size_t cap) {
    AudioObjectPropertyAddress a = {
        kAudioDevicePropertyDataSourceNameForIDCFString, kAudioObjectPropertyScopeInput,
        kAudioObjectPropertyElementMain };
    CFStringRef s = NULL;
    AudioValueTranslation t = { &sid, sizeof(sid), &s, sizeof(s) };
    UInt32 sz = sizeof(t);
    if (AudioObjectGetPropertyData(dev, &a, 0, NULL, &sz, &t) != noErr || !s) return 0;
    Boolean ok = CFStringGetCString(s, out, (CFIndex)cap, kCFStringEncodingUTF8);
    CFRelease(s);
    return ok ? 1 : 0;
}

static AudioObjectID find_device(const char *want) {
    AudioObjectPropertyAddress a = {
        kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain };
    UInt32 sz = 0;
    if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &a, 0, NULL, &sz) != noErr) return kAudioObjectUnknown;
    UInt32 n = sz / (UInt32)sizeof(AudioObjectID);
    AudioObjectID *ids = malloc(sz);
    if (!ids) return kAudioObjectUnknown;
    AudioObjectID found = kAudioObjectUnknown;
    if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &a, 0, NULL, &sz, ids) == noErr) {
        for (UInt32 i = 0; i < n; i++) {
            AudioObjectPropertyAddress na = {
                kAudioObjectPropertyName, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain };
            CFStringRef nm = NULL; UInt32 ns = sizeof(nm);
            if (AudioObjectGetPropertyData(ids[i], &na, 0, NULL, &ns, &nm) == noErr && nm) {
                char buf[256] = {0};
                CFStringGetCString(nm, buf, sizeof buf, kCFStringEncodingUTF8);
                CFRelease(nm);
                if (strcmp(buf, want) == 0) { found = ids[i]; break; }
            }
        }
    }
    free(ids);
    return found;
}

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: input-source get|list|set <device> [source]\n"); return 2; }
    const char *cmd = argv[1], *devname = argv[2];
    AudioObjectID dev = find_device(devname);
    if (dev == kAudioObjectUnknown) { fprintf(stderr, "no such device: %s\n", devname); return 1; }

    UInt32 cur = 0, csz = sizeof cur;
    int have_cur = AudioObjectGetPropertyData(dev, &kCurrent, 0, NULL, &csz, &cur) == noErr;

    if (!strcmp(cmd, "get")) {
        char nm[256] = {0};
        // No data source at all is normal: most devices have exactly one input
        // and do not model it. Say nothing and succeed, so callers can treat
        // "nothing to manage" and "managed, and correct" the same way.
        if (!have_cur) return 0;
        if (name_of(dev, cur, nm, sizeof nm)) printf("%s\n", nm);
        else printf("%u\n", cur);
        return 0;
    }

    UInt32 sz = 0;
    if (AudioObjectGetPropertyDataSize(dev, &kSources, 0, NULL, &sz) != noErr || sz == 0) return 0;
    UInt32 n = sz / (UInt32)sizeof(UInt32);
    UInt32 *srcs = malloc(sz);
    if (!srcs) return 1;
    if (AudioObjectGetPropertyData(dev, &kSources, 0, NULL, &sz, srcs) != noErr) { free(srcs); return 1; }

    if (!strcmp(cmd, "list")) {
        for (UInt32 i = 0; i < n; i++) {
            char nm[256] = {0};
            name_of(dev, srcs[i], nm, sizeof nm);
            printf("%s%s\n", (have_cur && srcs[i] == cur) ? "* " : "  ", nm[0] ? nm : "(unnamed)");
        }
        free(srcs);
        return 0;
    }

    if (!strcmp(cmd, "set")) {
        if (argc < 4) { fprintf(stderr, "set needs a source name\n"); free(srcs); return 2; }
        for (UInt32 i = 0; i < n; i++) {
            char nm[256] = {0};
            name_of(dev, srcs[i], nm, sizeof nm);
            if (nm[0] && strcasestr(nm, argv[3])) {
                OSStatus st = AudioObjectSetPropertyData(dev, &kCurrent, 0, NULL, sizeof(UInt32), &srcs[i]);
                free(srcs);
                if (st != noErr) { fprintf(stderr, "could not set input source: OSStatus %d\n", (int)st); return 1; }
                printf("%s\n", nm);
                return 0;
            }
        }
        fprintf(stderr, "no input source matching '%s'\n", argv[3]);
        free(srcs);
        return 1;
    }

    free(srcs);
    fprintf(stderr, "unknown command: %s\n", cmd);
    return 2;
}
