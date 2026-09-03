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

    -- Frosted glass behind the scratchpad (SUPER+S). Omarchy ships blur off;
    -- turning it on only affects translucent surfaces, and every window here
    -- is opaque (rule at the bottom), so the only visible effect is
    -- blur.special: the workspace underneath an open special workspace.
    dim_special = 0.25,
    blur = {
      enabled = true,
      special = true,
      size = 10,
      passes = 3,
      noise = 0.04, -- grain; this is what makes it read as brushed rather than smooth
      contrast = 0.9,
      brightness = 0.8,
      vibrancy = 0.2,
      vibrancy_darkness = 0.0,
      popups = false,
    },
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

-- Inset the scratchpad so the glass is actually visible around it; with the
-- stock 10px outer gap a single window covers nearly the whole screen.
hl.workspace_rule({ workspace = "special:scratchpad", gaps_out = 40, gaps_in = 8 })
