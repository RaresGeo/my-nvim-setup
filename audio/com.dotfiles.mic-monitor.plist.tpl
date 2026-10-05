<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Rendered from this template by audio/install.sh: launchd will not expand ~,
     so the paths have to be baked in.

     Sidetone: BlackHole back out to the headphones. It reads the sink rather
     than the mic on purpose, so what you hear is the gated signal, the same
     thing the far end of a call gets.

     `micctl monitor` only runs while docked, because undocked there is no
     headset to hear it in, and it refuses the built-in speakers outright: the
     mic hearing its own output through them is a feedback loop that a noise
     gate will hold wide open. It waits, resident, until both are satisfied,
     which is also what makes undocking, or unplugging headphones, a non event.
     That waiting is why the loop is in micctl and not in launchd: a job that
     exited every time it was undocked would be in the penalty box within the
     minute.

     KeepAlive is the backstop for micctl itself dying; ThrottleInterval keeps
     that from becoming a spin. -->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dotfiles.mic-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>{{ MICCTL }}</string>
        <string>monitor</string>
    </array>
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
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>{{ LOGDIR }}/mic-monitor.log</string>
    <key>StandardErrorPath</key>
    <string>{{ LOGDIR }}/mic-monitor.log</string>
</dict>
</plist>
