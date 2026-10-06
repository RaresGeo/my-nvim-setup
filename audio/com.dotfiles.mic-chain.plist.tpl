<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Rendered from this template by audio/install.sh: launchd will not expand ~,
     so the paths have to be baked in.

     This job is the gate itself: the mic, through a highpass and a noise gate,
     into BlackHole, which is what apps read. It has to be running for the mic
     to work at all once apps are pointed at BlackHole, hence RunAtLoad and
     KeepAlive.

     The retry loop lives inside `micctl chain`, NOT in launchd. micctl stays
     resident and restarts its own sox whenever CoreAudio reconfigures, so
     launchd sees one long lived process with nothing to throttle. Letting
     launchd do the respawning instead would put the job in the penalty box the
     first time the headphones were unplugged twice in quick succession, which
     is the same failure the dock watcher hit (see
     macos/dock/com.dotfiles.dock-watch.plist.tpl). KeepAlive is the backstop
     for micctl itself dying, and ThrottleInterval keeps that from spinning. -->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dotfiles.mic-chain</string>
    <key>ProgramArguments</key>
    <array>
        <string>{{ MICCTL }}</string>
        <string>chain</string>
    </array>
    <!-- launchd's default PATH has no Homebrew, and this job is entirely made
         of sox and SwitchAudioSource. micctl fixes its own PATH too; this keeps
         the job honest if that is ever edited out. -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>RunAtLoad</key>
    <true/>
    <!-- Standard would let App Nap and the CPU limiter throttle a process that
         is moving audio in real time; Interactive opts out of both. A gate
         starved of CPU drops the signal, which sounds exactly like a mic that
         has died. -->
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>{{ LOGDIR }}/mic-chain.log</string>
    <key>StandardErrorPath</key>
    <string>{{ LOGDIR }}/mic-chain.log</string>
</dict>
</plist>
