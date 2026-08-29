-- Omarchy 4.x (quattro) port of looknfeel.conf.

-- Custom center-master layout: like master orientation=center, but sides cap
-- at 2 rows and split horizontally from the 6th window (hypr/centermaster.lua).
require("hypr.centermaster")

hl.config({
  general = {
    layout = "lua:centermaster",
  },

  decoration = {
    -- Use round window corners.
    rounding = 8,
  },

  master = {
    mfact = 0.5,
    always_keep_position = true,
    slave_count_for_center_master = 0,
    orientation = "center",
    new_status = "slave", -- quattro default is "master"
  },
})

-- Fully opaque windows everywhere (overrides theme opacity).
o.window(".*", { opacity = "1 1" })
