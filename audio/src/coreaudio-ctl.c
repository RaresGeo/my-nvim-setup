// coreaudio-ctl -- read and set CoreAudio device properties that macOS exposes
// in System Settings but ships no command line for.
//
// Four of them, all needed by micctl and all VOLATILE -- they are USB-audio-class
// controls, so the device resets them to its defaults on every re-enumeration.
// Handing the card to another machine over a USB switch and taking it back is a
// re-enumeration.
//
//   input-source   which physical input the device listens on
//   playthru       the device's own analog monitoring of that input back to its
//                  output: zero latency, because the signal never reaches the
//                  host. This is the sidetone.
//   mute           the device's own capture mute flag, reached BY NAME. That is
//                  the part SwitchAudioSource cannot do: its -m ignores -s and
//                  only ever acts on the current default input. micctl needs the
//                  flag on the microphone rather than on the default input,
//                  because the default input here is the sink every app holds --
//                  and an app that can see the flag treats a deliberate mute as
//                  a fault and says so over its own mute button.
//   volume         the input gain as a 0..1 scalar, which is how a microphone
//                  with no mute control of its own gets muted.
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
//   coreaudio-ctl input-source get  <device>
//   coreaudio-ctl input-source list <device>            '*' marks the current one
//   coreaudio-ctl input-source set  <device> <substring>
//   coreaudio-ctl playthru     get  <device>
//   coreaudio-ctl playthru     set  <device> <0|1> [dB]
//   coreaudio-ctl mute         get  <device>
//   coreaudio-ctl mute         set  <device> <0|1|toggle>
//   coreaudio-ctl volume       get  <device>
//   coreaudio-ctl volume       set  <device> <0..1>
//
// Exit 3 is reserved for "this device has no such control", as distinct from a
// read or a write that failed, so a caller can fall back rather than report a
// mute it did not actually get.
#include <CoreAudio/CoreAudio.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const AudioObjectPropertyAddress kSources = {
    kAudioDevicePropertyDataSources, kAudioObjectPropertyScopeInput, kAudioObjectPropertyElementMain };
static const AudioObjectPropertyAddress kCurrent = {
    kAudioDevicePropertyDataSource, kAudioObjectPropertyScopeInput, kAudioObjectPropertyElementMain };
static const AudioObjectPropertyAddress kThru = {
    kAudioDevicePropertyPlayThru, kAudioDevicePropertyScopePlayThrough, kAudioObjectPropertyElementMain };
static const AudioObjectPropertyAddress kMute = {
    kAudioDevicePropertyMute, kAudioObjectPropertyScopeInput, kAudioObjectPropertyElementMain };

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

// The monitoring level, in dB, on each channel element. Element 0 carries the
// on/off switch and no volume, so the channels are walked from 1.
static void thru_db_print(AudioObjectID dev) {
    for (UInt32 el = 1; el <= 2; el++) {
        AudioObjectPropertyAddress a = {
            kAudioDevicePropertyPlayThruVolumeDecibels, kAudioDevicePropertyScopePlayThrough, el };
        Float32 db = 0; UInt32 sz = sizeof db;
        if (AudioObjectGetPropertyData(dev, &a, 0, NULL, &sz, &db) == noErr)
            printf("  ch%u %.2f dB\n", el, db);
    }
}

static int thru_db_set(AudioObjectID dev, Float32 db) {
    int bad = 0;
    for (UInt32 el = 1; el <= 2; el++) {
        AudioObjectPropertyAddress a = {
            kAudioDevicePropertyPlayThruVolumeDecibels, kAudioDevicePropertyScopePlayThrough, el };
        if (AudioObjectSetPropertyData(dev, &a, 0, NULL, sizeof db, &db) != noErr) bad = 1;
    }
    return bad;
}

static int playthru(AudioObjectID dev, int argc, char **argv) {
    if (!AudioObjectHasProperty(dev, &kThru)) {
        fprintf(stderr, "device has no playthrough\n");
        return 1;
    }
    if (!strcmp(argv[1], "get")) {
        UInt32 v = 0, sz = sizeof v;
        if (AudioObjectGetPropertyData(dev, &kThru, 0, NULL, &sz, &v) != noErr) return 1;
        printf("%u\n", v);
        thru_db_print(dev);
        return 0;
    }
    if (!strcmp(argv[1], "set")) {
        if (argc < 4) { fprintf(stderr, "playthru set needs 0 or 1\n"); return 2; }
        UInt32 v = (UInt32)atoi(argv[3]);
        OSStatus st = AudioObjectSetPropertyData(dev, &kThru, 0, NULL, sizeof v, &v);
        if (st != noErr) { fprintf(stderr, "could not set playthru: OSStatus %d\n", (int)st); return 1; }
        if (argc > 4 && thru_db_set(dev, (Float32)atof(argv[4])))
            fprintf(stderr, "playthru set, but the level was refused\n");
        // Read back rather than trusting the write. CoreAudio returns noErr for a
        // set the driver then undoes, which is exactly how the input source
        // behaves, so saying "done" on the strength of the status would lie.
        UInt32 rb = 0, sz = sizeof rb;
        if (AudioObjectGetPropertyData(dev, &kThru, 0, NULL, &sz, &rb) == noErr && rb != v) {
            fprintf(stderr, "playthru read back as %u, not %u\n", rb, v);
            return 1;
        }
        printf("%u\n", v);
        return 0;
    }
    fprintf(stderr, "unknown playthru command: %s\n", argv[1]);
    return 2;
}

// The capture mute flag. It lives on the master element: every input measured
// here -- a Sound BlasterX G6, the built-in mic, a C920 webcam -- answers on
// element 0 and on no channel element, and reports it settable there.
//
// Unlike SwitchAudioSource's write-only toggle this reads back, so the state
// never has to be inferred from a record that can drift.
static int mute_cmd(AudioObjectID dev, const char *verb, const char *arg) {
    if (!AudioObjectHasProperty(dev, &kMute)) {
        fprintf(stderr, "device has no input mute control\n");
        return 3;
    }
    UInt32 cur = 0, sz = sizeof cur;
    if (AudioObjectGetPropertyData(dev, &kMute, 0, NULL, &sz, &cur) != noErr) {
        fprintf(stderr, "could not read the input mute flag\n");
        return 1;
    }
    if (!strcmp(verb, "get")) { printf("%u\n", cur ? 1u : 0u); return 0; }
    if (strcmp(verb, "set")) { fprintf(stderr, "unknown mute command: %s\n", verb); return 2; }
    if (!arg) { fprintf(stderr, "mute set needs 0, 1 or toggle\n"); return 2; }

    // `toggle` reads and flips inside this one process on purpose. It runs on a
    // keypress that already pays for a sidetone write and an HID write for the
    // lamp, and a separate read from the shell would add a whole second CoreAudio
    // round trip -- 46ms measured -- to that budget.
    UInt32 want = !strcmp(arg, "toggle") ? (cur ? 0u : 1u) : (atoi(arg) ? 1u : 0u);

    Boolean settable = 0;
    if (AudioObjectIsPropertySettable(dev, &kMute, &settable) != noErr || !settable) {
        fprintf(stderr, "device's input mute flag is read-only\n");
        return 3;
    }
    OSStatus st = AudioObjectSetPropertyData(dev, &kMute, 0, NULL, sizeof want, &want);
    if (st != noErr) {
        fprintf(stderr, "could not set the input mute flag: OSStatus %d\n", (int)st);
        return 1;
    }
    // Read back rather than trusting the write, for the same reason playthru
    // does: CoreAudio returns noErr for a set the driver then undoes.
    UInt32 rb = 0; sz = sizeof rb;
    if (AudioObjectGetPropertyData(dev, &kMute, 0, NULL, &sz, &rb) == noErr && (rb ? 1u : 0u) != want) {
        fprintf(stderr, "input mute read back as %u, not %u\n", rb, want);
        return 1;
    }
    printf("%u\n", want);
    return 0;
}

// How many input channels the device has, so the volume walk below has an end.
// Two on failure, which is what every device here actually has.
static UInt32 input_channels(AudioObjectID dev) {
    AudioObjectPropertyAddress a = {
        kAudioDevicePropertyStreamConfiguration, kAudioObjectPropertyScopeInput,
        kAudioObjectPropertyElementMain };
    UInt32 sz = 0;
    if (AudioObjectGetPropertyDataSize(dev, &a, 0, NULL, &sz) != noErr || sz == 0) return 2;
    AudioBufferList *bl = malloc(sz);
    if (!bl) return 2;
    UInt32 n = 0;
    if (AudioObjectGetPropertyData(dev, &a, 0, NULL, &sz, bl) == noErr)
        for (UInt32 i = 0; i < bl->mNumberBuffers; i++) n += bl->mBuffers[i].mNumberChannels;
    free(bl);
    return n ? n : 2;
}

// The input gain, as a 0..1 scalar. Which element carries it is per device --
// the built-in mic has it on the master element and the G6 on its two channels
// and not on the master -- so every settable element from 0 up to the channel
// count is written, and a get reports the loudest.
static int volume_cmd(AudioObjectID dev, const char *verb, const char *arg) {
    UInt32 top = input_channels(dev);

    if (!strcmp(verb, "get")) {
        // The loudest, so that a device with one channel already pulled down
        // comes back to the level it was really recording at rather than to the
        // quieter side of an imbalance.
        Float32 best = -1;
        for (UInt32 el = 0; el <= top; el++) {
            AudioObjectPropertyAddress a = {
                kAudioDevicePropertyVolumeScalar, kAudioObjectPropertyScopeInput, el };
            Float32 v = 0; UInt32 sz = sizeof v;
            if (!AudioObjectHasProperty(dev, &a)) continue;
            if (AudioObjectGetPropertyData(dev, &a, 0, NULL, &sz, &v) == noErr && v > best) best = v;
        }
        if (best < 0) { fprintf(stderr, "device has no input volume control\n"); return 3; }
        printf("%.4f\n", best);
        return 0;
    }
    if (strcmp(verb, "set")) { fprintf(stderr, "unknown volume command: %s\n", verb); return 2; }
    if (!arg) { fprintf(stderr, "volume set needs a 0..1 scalar\n"); return 2; }

    Float32 want = (Float32)atof(arg);
    if (want < 0) want = 0;
    if (want > 1) want = 1;
    int wrote = 0, refused = 0;
    for (UInt32 el = 0; el <= top; el++) {
        AudioObjectPropertyAddress a = {
            kAudioDevicePropertyVolumeScalar, kAudioObjectPropertyScopeInput, el };
        Boolean settable = 0;
        if (!AudioObjectHasProperty(dev, &a)) continue;
        if (AudioObjectIsPropertySettable(dev, &a, &settable) != noErr || !settable) continue;
        if (AudioObjectSetPropertyData(dev, &a, 0, NULL, sizeof want, &want) != noErr) { refused = 1; continue; }
        Float32 rb = -1; UInt32 sz = sizeof rb;
        if (AudioObjectGetPropertyData(dev, &a, 0, NULL, &sz, &rb) == noErr && fabsf(rb - want) > 0.01f) refused = 1;
        else wrote++;
    }
    if (!wrote) {
        fprintf(stderr, "device has no settable input volume\n");
        return refused ? 1 : 3;
    }
    if (refused) { fprintf(stderr, "input volume was refused on some channels\n"); return 1; }
    printf("%.4f\n", want);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 4) {
        fprintf(stderr, "usage: coreaudio-ctl input-source get|list|set <device> [source]\n");
        fprintf(stderr, "       coreaudio-ctl playthru get|set <device> [0|1] [dB]\n");
        fprintf(stderr, "       coreaudio-ctl mute get|set <device> [0|1|toggle]\n");
        fprintf(stderr, "       coreaudio-ctl volume get|set <device> [0..1]\n");
        return 2;
    }
    // coreaudio-ctl <group> <verb> <device> [...]
    const char *group = argv[1];
    const char *cmd = argv[2], *devname = argv[3];
    AudioObjectID dev = find_device(devname);
    if (dev == kAudioObjectUnknown) { fprintf(stderr, "no such device: %s\n", devname); return 1; }

    if (!strcmp(group, "mute"))
        return mute_cmd(dev, cmd, argc > 4 ? argv[4] : NULL);
    if (!strcmp(group, "volume"))
        return volume_cmd(dev, cmd, argc > 4 ? argv[4] : NULL);
    if (!strcmp(group, "playthru")) {
        // Shift so playthru() sees its own verb at argv[1] and args from argv[3].
        char *sub[6] = { argv[0], argv[2], argv[3], argc > 4 ? argv[4] : NULL,
                         argc > 5 ? argv[5] : NULL, NULL };
        return playthru(dev, argc - 1, sub);
    }
    if (strcmp(group, "input-source")) {
        fprintf(stderr, "unknown group: %s\n", group);
        return 2;
    }

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
        if (argc < 5) { fprintf(stderr, "set needs a source name\n"); free(srcs); return 2; }
        for (UInt32 i = 0; i < n; i++) {
            char nm[256] = {0};
            name_of(dev, srcs[i], nm, sizeof nm);
            if (nm[0] && strcasestr(nm, argv[4])) {
                OSStatus st = AudioObjectSetPropertyData(dev, &kCurrent, 0, NULL, sizeof(UInt32), &srcs[i]);
                free(srcs);
                if (st != noErr) { fprintf(stderr, "could not set input source: OSStatus %d\n", (int)st); return 1; }
                printf("%s\n", nm);
                return 0;
            }
        }
        fprintf(stderr, "no input source matching '%s'\n", argv[4]);
        free(srcs);
        return 1;
    }

    free(srcs);
    fprintf(stderr, "unknown command: %s\n", cmd);
    return 2;
}
