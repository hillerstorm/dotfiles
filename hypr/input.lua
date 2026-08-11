-- Omarchy 4.x (quattro) port of input.conf.

hl.config({
  input = {
    kb_layout = "se",
    -- Replaces quattro's default "compose:caps,shift:both_capslock_cancel".
    kb_options = "compose:rctrl,caps:swapescape,altwin:swap_lalt_lwin",

    repeat_rate = 40,
    repeat_delay = 600,

    numlock_by_default = true,
    follow_mouse = 2,
  },
})

-- Disable pointer acceleration for the ydotool virtual mouse, so
-- programmatic absolute moves land on exact coordinates.
hl.device({
  name = "ydotoold-virtual-device-1",
  accel_profile = "flat",
  sensitivity = 0,
})

-- Terminal touchpad scroll factors are now in Omarchy's defaults
-- (default/hypr/input.lua), no need to repeat them here.
