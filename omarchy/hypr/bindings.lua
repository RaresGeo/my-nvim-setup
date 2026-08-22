-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Migrated from old bindings.conf --

hl.unbind("SUPER + SHIFT + W")

-- Extra app launches not covered by defaults
o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
o.bind("SUPER + B", "Microphone mute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")

-- Custom region screenshot
o.bind("CTRL + ALT + S", "Screenshot of region", "omarchy-capture-screenshot smart")

-- Vim-style (H/J/K/L) focus movement instead of arrow keys.
-- This frees up SUPER+J (was: toggle window split), SUPER+K (was: keybindings),
-- and SUPER+L (was: toggle workspace layout), so those are relocated below.
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")

o.bind("SUPER + H", "Move focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Move focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Move focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Move focus right", hl.dsp.focus({ direction = "r" }))

o.bind("SUPER + SHIFT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + K", "Show key bindings", "omarchy-menu-keybindings")
o.bind("SUPER + SHIFT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
