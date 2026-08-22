-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Migrated from old autostart.conf: launch WhatsApp and Google Calendar as
-- webapps into the scratchpad workspace on login.
-- (The old walker-launcher restart lines were dropped: walker no longer
-- ships in Quattro, replaced by the Omarchy shell's own menu.)
hl.on("hyprland.start", function()
  hl.exec_cmd(o.launch_webapp("https://web.whatsapp.com/"), { workspace = "special:scratchpad" })
  hl.exec_cmd(o.launch_webapp("https://calendar.google.com/calendar/u/0/r?pli=1"), { workspace = "special:scratchpad" })
end)
