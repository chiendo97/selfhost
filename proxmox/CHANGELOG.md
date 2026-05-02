# cle-pve Infrastructure Changelog

## 2026-05-01

- Completed main Unraid-to-Proxmox cutover state.
- Destroyed old VM 100 `unraid` and VM 120 `apps-docker-pve`.
- Kept `nas-pve` because VM 121 still needs RW media access for downloads and
  asset workflows.
- Reduced `nas-pve` to media-only exports:
  - `/tank/media -> /shares/media`
  - VM 121 `192.168.50.121` has RW NFS access.
  - `192.168.50.0/24` has RO NFS media access.
  - Removed stale `selfhost`, `immich-app`, `frigate`, and `homelab` shares.
- Removed VM 121 `/mnt/user/frigate` NFS mount from the NixOS config.
- Moved Plex app data from `/fast/selfhost/plex/library` into CT 110 rootfs at
  `/var/lib/plexmediaserver`.
- Moved Jellyfin app data from `/fast/selfhost/jellyfin/config` into CT 111
  rootfs at `/var/lib/jellyfin`.
- Moved Frigate config from `/tank/frigate/config` into CT 113 rootfs at
  `/config`.
- Kept Frigate recordings on `/tank/frigate/storage`, mounted into CT 113 at
  `/media/frigate`.
- Removed all live PVE references to `/fast/selfhost`.
- Renamed old `/fast/selfhost` dataset to `fast/selfhost-decom-20260501` and
  set it read-only as rollback.
- Updated `backup-pve` so Kopia only backs up Immich photos/database dumps from
  `/fast/immich-app/photos`; old `/source/selfhost` policy was deleted.
- Added/verified Proxmox guest backup job `nightly-guests`.
- Created/restored temporary CT 910 and VM 911 as a Proxmox backup restore
  drill, then destroyed both temporary guests.
- Added Kopia backup layer in CT 115 `backup-pve`.
- Verified HTTP access for Plex, Jellyfin, Frigate, and Immich after the data
  moves.
- Added VM 121 Traefik routes for `proxmox.chienlt.com` and
  `kopia.chienlt.com`.
- Added a Homepage `Media Storage` resources widget by mounting VM 121
  `/mnt/user/media` into the Homepage container as `/storage/media` read-only.
- Tuned LXC CPU and memory limits from Proxmox day/week max usage while keeping
  rootfs sizes unchanged.
- Added 16G host zram swap on `cle-pve` with `vm.swappiness=10`.
- Enabled in-guest zram swap for NixOS VMs 101 `homelab-pve` and 121
  `selfhost-pve`.
- Added VM 121 Traefik route for `bambuddy.chienlt.com` to N100 Bambuddy over
  Tailscale.
- Added an initial OpenTofu adoption scaffold under `proxmox/opentofu` for the
  existing Proxmox VMs/LXCs. The first pass uses import blocks,
  `prevent_destroy`, and `ignore_changes = all` so it can establish state before
  managing live guest settings.
- Created `opentofu@pve!cle-pve-adopt` with read-only audit permissions plus
  `VM.Config.Disk`, imported all 9 live guests into local OpenTofu state, and
  verified a no-op follow-up plan.

## Historical Notes

- The old migration runbook was intentionally replaced by current-state docs.
- `tank/media` and `tank/frigate` were migrated from Unraid disks.
- `fast/immich-app` remains the live Immich data dataset.
- `fast/domains` still contains old Unraid VM images and is not referenced by
  active Proxmox configs.
