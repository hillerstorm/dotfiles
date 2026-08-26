# Omarchy 4.0 "quattro" — post-migration notes

Migration **completed 2026-08-26** (3.8.5 → quattro via `omarchy-upgrade-to-quattro`).
The machine runs the **dev channel** (`omarchy-dev`, pacman repo pinned to
`pkgs.omarchy.org/edge`) by deliberate choice. The pre-flight planning that used
to live in this file is in git history (`git log -- hypr/QUATTRO.md`).

## Live config

The `*.lua` files in this directory are the config of record, deployed to
`~/.config/hypr/`. Quattro's Hyprland reads `hyprland.lua` as the entrypoint;
`.conf` files are dead and the ports were removed from this repo after cutover.
`hyprsunset.conf`, `xdph.conf`, and `scripts/wow-detect.sh` are still used.

**Never deploy the `.lua` files to a pre-quattro machine**: Hyprland 0.56+
prefers `hyprland.lua` over `hyprland.conf` when present, and `hyprland.lua`
dofile's `/usr/share/omarchy/default/hypr/bootstrap.lua`, which only exists
once the quattro package is installed. Without it: lua error, zero binds,
emergency mode (learned the hard way on 2026-08-26).

## Files omarchy rewrites — recheck after updates

- `/etc/sddm.conf.d/autologin.conf` — the bridge rewrote it once already,
  dropping our `Relogin=true` (re-add: `sed -i '/^\[Autologin\]/a Relogin=true'`).
  Autologin itself has no omarchy toggle; this file is the control (#6997 is
  by design on encrypted installs).
- `/usr/share/sddm/hyprland.conf` — carries our appended
  `input { kb_layout = se }`. Unowned by any package, but an omarchy migration
  could replace it. Without it the greeter is us-layout and the åäö account
  password cannot be typed. Escape hatch, needs no password:
  `docker run --rm --privileged --pid=host alpine nsenter -t 1 -m -u -i -n -- systemctl restart sddm`
- `~/.local/bin/{grok,crush,claude}` — `omarchy-refresh-applications` writes
  mise stubs regardless of the preinstalls-removed marker. claude's stub is
  the accepted install; delete grok/crush if they reappear.
- OpenLinkHub's pacman scriptlet disables its own service on upgrade —
  `systemctl enable --now openlinkhub` after updates that touch it.

## Known quirks (open upstream as of 2026-08-26)

- `pbp-toggle` (SUPER+SHIFT+P): `hyprctl keyword monitor` silently no-ops
  under the Lua config (#6968). Rework via a Lua monitor override when needed.
- Network panel shows "Cloudflare": cosmetic — `omarchy-dns` reads only
  `/etc/systemd/resolved.conf` (stale 3.x line) and ignores the
  `50-adguard.conf` drop-in that actually routes DNS to 192.168.1.52.
- Hand-editing `idle.*` in `~/.config/omarchy/shell.json` silently kills the
  idle monitor until a shell restart (#8038) — use `omarchy toggle idle`.
- Keyboard layout can revert to `en` after sleep (#8060); desktop rarely sleeps.

## Verifying remote unlock after any UKI regeneration

`zz-remote-unlock.conf` reassigns HOOKS wholesale and sorts last, so it wins —
but verify after anything regenerates the UKI (kernel updates, omarchy
migrations). The UKI is world-readable; no sudo needed:

```sh
objcopy -O binary --only-section=.initrd /boot/EFI/Linux/omarchy_linux.efi /tmp/initrd
lsinitcpio -l /tmp/initrd | grep -cE 'dropbear|encryptssh'   # baseline: 6 + 1
objcopy -O binary --only-section=.cmdline /boot/EFI/Linux/omarchy_linux.efi /dev/stdout
# must contain: ip=192.168.1.39... cryptdevice=PARTUUID=00ef58bc-... root=/dev/mapper/root
```

The pre-dropbear fallback UKI lives in `/boot/uki-backup/`. The pre-quattro
anchor snapshot ("pre-quattro manual anchor") and the old checkout at
`~/.local/share/omarchy.omarchy-upgrade-to-quattro.20260826205418.bak` remain
until the machine has proven itself.

## Rollback: the advertised path is broken — use the manual one

Upstream #8047 (same root cause as #6634), confirmed on this machine: the
`btrfs-overlayfs` initcpio hook mounts an overlay over `/` on every read-only
snapshot boot, and `limine-snapper-sync` bails with "You are not in Btrfs"
before parsing arguments when `/` is an overlay. So from a snapshot boot,
`omarchy-snapshot restore` cannot ever work. The Limine "Snapshots" submenu
still *boots* snapshots fine — you just can't restore with the tooling.

Layout facts this procedure depends on (verified 2026-08-24):
- btrfs on `/dev/mapper/root` (LUKS, `cryptdevice=PARTUUID=00ef58bc-1b24-41ee-ac03-62d7c7e7c955:root`),
  top-level subvols `@ @home @pkg @log`; fstab and kernel cmdline pin `subvol=/@`.
- Snapper's `.snapshots` is a subvolume **nested inside `@`**
  (`/@/.snapshots/N/snapshot`), so it must be carried over when `@` is replaced.
- `/boot` is the ESP (`/dev/nvme0n1p1`, vfat) — **rolling back `@` does not
  roll back the UKI**.

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
itself), and verify remote unlock with the objcopy check above.
