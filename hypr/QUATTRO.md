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

## Day-one 4.0.0 findings (from upstream issues, 2026-08-15)

- **`sudo pacman -S --asexplicit bluez-tools` before upgrading** — the upgrade
  enables `bt-agent.service` (unit shipped by omarchy-settings) but nothing
  installs `/usr/bin/bt-agent` (bluez-tools), causing an infinite 2s restart
  loop (upstream #6992). We don't have bluez-tools installed, so we'd hit it.
- **Remote-unlock survives**: the script `--overwrite`s only its own
  `omarchy_hooks.conf`; our `zz-remote-unlock.conf` (sorts last, wins) keeps
  netconf/dropbear/encryptssh. **After upgrade, verify** the new UKI still has
  them: `lsinitcpio -l <initrd> | grep -E 'dropbear|encryptssh'` **before
  rebooting** (cf. #6876 — the drop-in replaces HOOKS wholesale).
- **`pbp-toggle` may break**: `hyprctl keyword monitor` silently no-ops under
  the Lua config on Hyprland 0.56 (#6968). If SUPER+SHIFT+P stops working,
  rework via Lua monitor override + reload once upstream settles.
- **LUKS unlock now auto-logs-in** to the session (#6997) — no user password
  after disk unlock. Combined with remote dropbear unlock, this means an
  unlocked machine has an open session. Check for an autologin toggle.
- **Stale Chromium SingletonLock** can loop migration 1786643346 after reboot
  (#6866) — chromium is installed here; make sure it exited cleanly pre-upgrade.
