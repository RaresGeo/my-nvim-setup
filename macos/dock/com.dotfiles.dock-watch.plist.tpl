<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Rendered from this template by macos/install.sh: launchd will not expand ~,
     so the path has to be baked in. Polling rather than an event: launchd has no
     USB trigger, and `dockctl apply` is a ~17ms no-op when nothing changed. -->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dotfiles.dock-watch</string>
    <key>ProgramArguments</key>
    <array>
        <string>{{ DOCKCTL }}</string>
        <string>apply</string>
    </array>
    <!-- launchd's default PATH has no Homebrew. dockctl resolves m1ddc itself,
         but DOCK_MONITOR_CMD and anything else it shells out to need this. -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StartInterval</key>
    <integer>5</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>{{ LOGDIR }}/dock-watch.log</string>
    <key>StandardErrorPath</key>
    <string>{{ LOGDIR }}/dock-watch.log</string>
</dict>
</plist>
