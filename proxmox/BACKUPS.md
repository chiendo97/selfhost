# cle-pve Backups

Last verified: 2026-05-08.

## Policy

There are two active backup layers:

1. Proxmox `vzdump` backs up all VM/LXC root disks and guest configs.
2. Kopia backs up Immich photos and Immich database dumps from
   `/fast/immich-app/photos`.

Large media stores are intentionally not backed up locally:

```text
/tank/media
/tank/frigate/storage
```

## Proxmox Guest Backups

Job:

```text
id: nightly-guests
node: cle-pve
schedule: 03:30
storage: tank-backup
mode: snapshot
compress: zstd
zstd: 1
all: 1
retention: keep-daily=7, keep-weekly=4, keep-monthly=3
```

Management surfaces:

```text
Proxmox UI -> Datacenter -> Backup
/etc/pve/jobs.cfg
pvesh get /cluster/backup
```

Included guests because `all=1`:

```text
101 homelab-pve
121 selfhost-pve
102 pulse
110 plex-pve
111 jellyfin-pve
112 nas-pve
113 frigate-pve
114 immich-pve
115 backup-pve
116 traefik-pve
```

Backup storage:

```text
tank-backup -> /tank/pve-backups
tank/pve-backups quota=2.5T
```

Latest observed archive set from 2026-05-01:

```text
VM101 homelab-pve: 34G
VM121 selfhost-pve: 27G
CT102 pulse: 424M
CT110 plex-pve: 605M
CT111 jellyfin-pve: 809M
CT112 nas-pve: 272M
CT113 frigate-pve: 2.0G
CT114 immich-pve: 2.0G
CT115 backup-pve: 302M
CT116 traefik-pve: not yet observed in a completed nightly archive
```

Important limitation: `vzdump` does not back up LXC bind mounts. It backs up
the guest rootfs and PVE config. This means Immich photos under
`/fast/immich-app` need the Kopia layer.

The shared zk notebook now lives on `/fast/zk` and is bind-mounted into
`nas-pve`, then NFS-mounted by `homelab-pve` and `selfhost-pve`. It is not
covered by Proxmox guest backups unless a separate dataset backup policy is
added.

Plex, Jellyfin, and Frigate config now live inside their LXC rootfs volumes, so
they are covered by the Proxmox guest backups.

## Kopia Immich Backup

Kopia runs inside CT 115 `backup-pve`.

| Item | Value |
|---|---|
| CT | `115 backup-pve` |
| Address | `192.168.50.53` |
| Service | `kopia-server.service` |
| UI | `http://192.168.50.53:51515` |
| Repository | `/backups/kopia-local` inside CT |
| Host storage | `/tank/fast-backups/kopia-local` |

CT mounts:

```text
/fast/immich-app -> /source/immich-app ro
/tank/fast-backups -> /backups
```

Active Kopia policies:

```text
global
root@backup-pve:/source/immich-app/photos
```

Retention:

```text
keep-latest=10
keep-daily=14
keep-hourly=0
keep-weekly=0
keep-monthly=0
keep-annual=0
ignore-identical-snapshots=true
```

Immich database dumps are expected under:

```text
/source/immich-app/photos/backups
```

Kopia backs up these SQL dumps with the photo library. It does not create the
SQL dumps itself.

Secrets are only inside CT 115:

```text
/root/kopia-secrets.env
```

Do not commit this file or paste its values into docs.

## Restore Pattern

Restore to a staging path first. Do not restore directly over live app data.

List Proxmox backups:

```bash
ssh cle-pve 'pvesm list tank-backup --content backup'
```

List Kopia snapshots:

```bash
ssh cle-pve 'pct exec 115 -- bash -lc ". /root/kopia-secrets.env && kopia snapshot list --all"'
```

Restore a Kopia snapshot to staging:

```bash
ssh cle-pve 'pct exec 115 -- bash -lc ". /root/kopia-secrets.env && mkdir -p /restore-test && kopia restore <snapshot-id> /restore-test/<name>"'
```

After validation, stop the relevant application and copy files back
intentionally with ownership preserved.

## Restore Drills

Completed on 2026-05-01:

- CT102 restored to temporary CT 910, verified, then destroyed.
- VM101 restored to temporary VM 911, verified, then destroyed.
- Kopia restored a file from the old `/source/selfhost` snapshot to `/tmp`,
  verified it matched, then removed the temporary restore.

## Future PBS

Proxmox Backup Server is still useful later, especially on another machine or
external storage. On the same `cle-pve` host and same `tank` pool it improves
dedupe and retention, but it does not solve disaster recovery.
