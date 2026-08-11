-- Omarchy 4.x (quattro) port of bindings.conf.
--
-- omarchy_preinstalled_bindings = false (set in hyprland.lua) disables all
-- preinstalled app/webapp bindings; the ones we actually use are re-added
-- below. SUPER+C/V universal copy/paste is now a stock quattro binding
-- (terminal-aware, default/hypr/bindings/clipboard.lua) — no override needed.

-- Kept preinstalled bindings ("tmux attach || tmux new -s Work" is stock now).
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })

-- btop moved to SUPER+CTRL+T in quattro's defaults; keep the old muscle memory too.
o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })

-- Toggle CRG9 between full res and 2560x1440@60 for PBP mode (~/.local/bin/pbp-toggle).
o.bind("SUPER + SHIFT + P", "Toggle PBP resolution", "pbp-toggle")
