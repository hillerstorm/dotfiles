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
  **DONE 2026-08-21** — the marker exists. It had to be created by hand: the
  bridge only writes it when `bindings.lua` matches a stock sha256, which our
  customized bindings never will.

## Day-one 4.0.0 findings (from upstream issues, 2026-08-15)

- **bluez-tools must be installed before upgrading** — the upgrade enables
  `bt-agent.service` (unit shipped by omarchy-settings) but nothing installs
  `/usr/bin/bt-agent` (bluez-tools), causing an infinite 2s restart loop
  (upstream #6992; `bluez-tools` only appears in the fresh-install package
  list, never in the upgrade path). **DONE 2026-08-21**: `bluez-tools` and
  `bluez-utils` (same gap, `bluetoothctl` was missing too) are installed.
- **claude-code pacman package removed 2026-08-21** (with `/opt/claude-code`
  and `/usr/bin/claude`) — the native installer at `~/.local/bin/claude` is
  the only install now. That does **not** close the mise-wrapper window
  (verified against origin/quattro 2026-08-25): the upgrade runs
  `omarchy-refresh-applications` → `install/user/mise.sh` →
  `omarchy-mise-install claude`, which does `rm -f ~/.local/bin/claude` and
  writes a mise stub there — the preinstalls-removed marker does not gate it.
  **Decision 2026-08-25: let the stub win.** The native install was chosen for
  its auto-updater, and the stub covers that: `mise use -g claude` on every
  launch (release-age cooldown zeroed), new versions installable ~1-3h after
  release (GitHub release lag + mise's 1h version cache). Verified: 17ms warm
  launch overhead; offline + cold cache still launches the installed version
  (so the claude-rc boot autostart, which uses `$HOME/.local/bin/claude`, is
  safe); `claude update` under mise is a harmless refusal. Known trade-offs:
  new-version downloads happen synchronously at launch, and pinning a version
  means editing the stub (which `omarchy-refresh-applications` rewrites).
  After the upgrade proves out: `rm -rf ~/.local/share/claude` to drop the
  orphaned native copies. Rollback to native: rerun the native installer, or
  `ln -sfn ~/.local/share/claude/versions/<v> ~/.local/bin/claude` while the
  copies still exist. Crash prompts / menu launches exec `claude` from PATH
  either way; set `omarchy default agent claude` once, since no default ships.
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

## 4.0.1 released 2026-08-25 — checklist unchanged

Mostly security fixes ("Fast-Follow Fixes",
https://github.com/basecamp/omarchy/releases/tag/v4.0.1). Upgrade from 4.0 is
`Update > Omarchy`; a fresh quattro bridge from 3.x should land here too.

**Every issue tracked in this doc is still open as of 4.0.1** (verified via
`gh issue view` on release day): #6992 bt-agent loop, #6968 `hyprctl keyword`
no-op, #6997 LUKS autologin, #6866 Chromium SingletonLock, #8047/#6634 broken
snapshot restore, #6876 HOOKS replacement. The pre-upgrade checklist and the
manual rollback procedure below all still apply.

What 4.0.1 changes for this machine:

- **#8129 fixed**: USB device names are no longer executed as Hyprland Lua.
  One less reason to fear the Lua config; nothing to do on our side.
- **#8056/#8098**: the user is no longer put in the `docker` group; sudoless
  Docker is opt-in via a menu toggle (which offers a reboot). After upgrading,
  check `groups | grep docker` before assuming the Docker bindings work.
- **#7001** (claude/codex launched with auto-review instead of
  `--dangerously-skip-permissions`) is moot here — preinstalls are removed and
  claude runs from `~/.local/bin`.
- The `o.shell_succeeds()` fix (#6939) doesn't touch us; none of our `*.lua`
  ports use it.

## Rollback: the advertised path is broken — use the manual one (2026-08-24)

Upstream #8047 (same root cause as #6634), **confirmed on this machine**: the
`btrfs-overlayfs` initcpio hook (last hook in both our HOOKS lines) mounts an
overlay over `/` on every read-only snapshot boot, and `limine-snapper-sync`
bails with "You are not in Btrfs" before parsing arguments when `/` is an
overlay. So from a snapshot boot, `omarchy-snapshot restore` (→
`limine-snapper-restore`) cannot ever work. The Limine "Snapshots" submenu
still *boots* snapshots fine — old UKI + matching kernel are preserved in
`/boot/<machine-id>/limine_history/` — you just can't restore from one with
the tooling. Restore by hand instead.

Layout facts this procedure depends on (verified 2026-08-24):
- btrfs on `/dev/mapper/root` (LUKS, `cryptdevice=PARTUUID=00ef58bc-1b24-41ee-ac03-62d7c7e7c955:root`),
  top-level subvols `@ @home @pkg @log`; fstab and kernel cmdline pin `subvol=/@`.
- Snapper's `.snapshots` is a subvolume **nested inside `@`**
  (`/@/.snapshots/N/snapshot`), so it must be carried over when `@` is replaced.
- `/boot` is the ESP (`/dev/nvme0n1p1`, vfat) — **rolling back `@` does not
  roll back the UKI**.

### Before upgrading

1. Anchor snapshot that retention can't delete — `omarchy-snapshot create`
   uses `-c number`, and quattro's template sets `NUMBER_LIMIT=5`, so the
   bridge's own pre-upgrade snapshot can rotate out. A plain snapper create
   has no cleanup algorithm and survives everything:

   ```sh
   sudo snapper -c root create -d "pre-quattro manual anchor"
   sudo limine-snapper-sync   # get it into the boot menu + preserve current UKI
   ```

2. `sudo pacman -S arch-install-scripts` — the snapshot-boot recovery
   environment has no `arch-chroot` otherwise (a live USB does).

### Restoring (from a snapshot boot or a live USB)

Preferred environment: boot the anchor from Limine's Snapshots submenu — full
desktop on the old kernel, overlay means nothing you do to `/` persists, but
mounts of the real device are real writes. If nothing boots at all, use an
Arch/Omarchy live USB and first run
`cryptsetup open /dev/disk/by-partuuid/00ef58bc-1b24-41ee-ac03-62d7c7e7c955 root`.

```sh
# 1. Find the target snapshot number N ("pre-quattro manual anchor"):
sudo snapper -c root list        # or: cat /boot/*/limine_history/snapshots.json

# 2. Mount the btrfs top level and swap @:
sudo mount -o subvolid=5 /dev/mapper/root /mnt
cd /mnt
sudo mv @ @broken
sudo btrfs subvolume snapshot @broken/.snapshots/N/snapshot @   # writable copy

# 3. Carry the snapshot store into the new @ (snapshots don't capture nested
#    subvols, so the fresh @ only has an empty .snapshots dir):
sudo rmdir @/.snapshots
sudo mv @broken/.snapshots @/.snapshots

# 4. Regenerate the UKI from the restored root. The ESP still holds the
#    post-upgrade UKI; if the upgrade touched the kernel or initcpio config,
#    it won't match the restored /usr/lib/modules:
sudo mount -o subvol=/@ /dev/mapper/root /mnt/@broken/mnt   # any scratch mountpoint
sudo mount /dev/nvme0n1p1 /mnt/@broken/mnt/boot
sudo arch-chroot /mnt/@broken/mnt mkinitcpio -P

# 5. Unmount everything and reboot into the normal Omarchy entry.
```

Afterwards, from the restored system: `sudo btrfs subvolume delete /mnt/@broken`
(mount top level again first; keep it around until the machine has proven
itself). Verify remote unlock survived the UKI regen (the UKI is a PE binary,
so extract the initrd section first):

```sh
objcopy -O binary --only-section=.initrd /boot/EFI/Linux/omarchy_linux.efi /tmp/initrd
lsinitcpio -l /tmp/initrd | grep -E 'dropbear|encryptssh'
```

The pre-dropbear fallback UKI lives in `/boot/uki-backup/`.
