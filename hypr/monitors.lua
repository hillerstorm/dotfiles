-- Omarchy 4.x (quattro) port of monitors.conf.
-- Samsung CRG9 49" super-ultrawide: straight 1x setup.
-- (Quattro's stock default is GDK_SCALE=2 + auto scale — wrong for this display.)

hl.env("GDK_SCALE", "1")
hl.monitor({ output = "", mode = "5120x1440@120", position = "auto", scale = 1 })
