-- Omarchy 4.x (quattro) port of hyprland.conf — drop into ~/.config/hypr/
-- after running omarchy-upgrade-to-quattro.

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Keep core WM bindings but drop Omarchy's preinstalled app/webapp bindings
-- (Spotify, Signal, Obsidian, HEY, WhatsApp, X, ...). The few we actually use
-- (Tmux, Docker, YouTube) are re-added in hypr/bindings.lua.
omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Personal overrides, loaded after Omarchy's defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- No gaps on workspaces with a single tiled window (or a fullscreen one).
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })

-- Tiled windows on those gapless workspaces also lose borders and rounding.
o.window({ float = 0, workspace = "w[tv1]s[false]" }, { border_size = 0, rounding = 0 })
o.window({ float = 0, workspace = "f[1]s[false]" }, { border_size = 0, rounding = 0 })

-- World of Warcraft: fully opaque, no border/rounding.
o.window({ class = "steam_app_0", title = "World of Warcraft" }, { opacity = "1.0", border_size = 0, rounding = 0 })
o.window("steam_app_0", { opacity = "1.0" })

hl.config({
  cursor = {
    no_warps = true,
  },
})
