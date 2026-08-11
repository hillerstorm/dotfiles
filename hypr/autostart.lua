-- Omarchy 4.x (quattro) port of autostart.conf.

-- WoW detection: swap to master, drop gaps, hide the bar while WoW runs.
o.exec_on_start(os.getenv("HOME") .. "/.config/hypr/scripts/wow-detect.sh")
