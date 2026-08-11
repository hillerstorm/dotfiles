# Omarchy 4.0 "quattro" migration notes

Quattro replaces Hyprland's `.conf` config with Lua (`hyprland.lua` entrypoint).
The `*.lua` files in this directory are pre-written ports of our `*.conf`
customizations, verified against `origin/quattro` of basecamp/omarchy and the
upstream Hyprland Lua API (`hl.*`).

## Deploying (after running `omarchy-upgrade-to-quattro`)

The upgrade installs stock `~/.config/hypr/*.lua` files (backing up nothing of
ours — the old `.conf` files are left in place but go **dead** after reboot).
Replace the stock Lua files with these:

```sh
cp ~/src/dotfiles/hypr/*.lua ~/.config/hypr/
hyprctl reload   # or reboot for the full cutover
```

## What's covered

| Old file | Port | Notes |
|---|---|---|
| `hyprland.conf` | `hyprland.lua` | workspace no-gaps rules, WoW windowrules, cursor no_warps, `omarchy_preinstalled_bindings = false` |
| `monitors.conf` | `monitors.lua` | CRG9 5120x1440@120, GDK_SCALE=1 (stock quattro default is 2!) |
| `input.conf` | `input.lua` | se layout, compose:rctrl + caps:swapescape + altwin swap, repeat_delay 600, follow_mouse 2, ydotool flat-accel device |
| `bindings.conf` | `bindings.lua` | Tmux/Docker/YouTube re-added (preinstalled binds disabled), btop on SUPER+SHIFT+T, pbp-toggle |
| `looknfeel.conf` | `looknfeel.lua` | master layout + center-master config, rounding 8, global opacity 1 1 |
| `autostart.conf` | `autostart.lua` | wow-detect.sh |
| `scripts/wow-detect.sh` | updated in place | now works on both 3.x (waybar) and 4.x (`omarchy-toggle-bar`) |

## Not config files — do manually after upgrade

- **Auto-lock comes back**: hypridle (and our never-lock `hypridle.conf`) is
  gone; the Quickshell shell defaults to screensaver@150s / lock@300s.
  Re-disable with `omarchy-toggle-idle` (bound to SUPER+CTRL+I) or edit the
  `idle` section of `~/.config/omarchy/shell.json`.
- **SUPER+C/V universal copy/paste** is stock in quattro (terminal-aware) —
  our old override is intentionally not ported.
- **Waybar tweaks** (module order, weather removed, margins) must be redone as
  the bar widget layout in `~/.config/omarchy/shell.json`.
- **Mako colors**: notifications are shell-themed now; old config is orphaned.
- To skip quattro's third-party agent preinstalls (grok/crush/oh-my-pi):
  `touch ~/.local/state/omarchy/preinstalls-removed` **before** upgrading.
