<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Rendered from this template by macos/install.sh: launchd will not expand ~,
     so the path has to be baked in. Polling rather than an event: launchd has no
     USB trigger, and `dockctl apply` is a ~17ms no-op when nothing changed.

     The poll loop lives inside `dockctl watch`, NOT in a StartInterval here. A
     5s StartInterval is below launchd's 10s minimum runtime, so launchd treated
     every poll as a process exiting too soon and throttled it; the pile-up of
     intervals missed during sleep then put the job in the penalty box, where it
     answered EX_CONFIG and refused to spawn until it was reloaded by hand. One
     resident process has no respawns to throttle. KeepAlive brings it back if it
     ever does die, and ThrottleInterval keeps that from becoming a spin. -->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dotfiles.dock-watch</string>
    <key>ProgramArguments</key>
    <array>
        <string>{{ DOCKCTL }}</string>
        <string>watch</string>
    </array>
    <!-- launchd's default PATH has no Homebrew. dockctl resolves m1ddc itself,
         but DOCK_MONITOR_CMD and anything else it shells out to need this. -->
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
    <key>StandardOutPath</key>
    <string>{{ LOGDIR }}/dock-watch.log</string>
    <key>StandardErrorPath</key>
    <string>{{ LOGDIR }}/dock-watch.log</string>
</dict>
</plist>
