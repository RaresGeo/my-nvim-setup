-- Change the default Omarchy look'n'feel.

-- Migrated from old looknfeel.conf.
hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 5,
    border_size = 3,
  },
})

hl.config({
  decoration = {
    rounding = 1,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
hl.config({
  layout = {
    -- Avoid overly wide single-window layouts on wide screens.
    single_window_aspect_ratio = { 16, 9 },
  },
})

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
