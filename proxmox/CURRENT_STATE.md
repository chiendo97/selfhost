# cle-pve Current State

Last verified: 2026-05-01.

## Host

| Item | Value |
|---|---|
| Hostname | `cle-pve` |
| LAN IP | `192.168.50.13` |
| Proxmox | `pve-manager/9.1.9` |
| Kernel | `6.17.13-4-pve` |
| Access | `ssh cle-pve` |
| UI | `https://192.168.50.13:8006` |

## Guests

| ID | Type | Name | Address | Purpose |
|---:|---|---|---|---|
| 101 | VM | `homelab-pve` | `192.168.50.130` | NixOS homelab host managed from dotfiles |
| 121 | VM | `selfhost-pve` | `192.168.50.121`, tail `100.81.144.82` | NixOS Docker host for selfhost stack, Traefik, Homepage, Jellyseerr |
| 102 | LXC | `pulse` | `192.168.50.18` | Pulse monitoring |
| 110 | LXC | `plex-pve` | `192.168.50.242` | Plex with Intel iGPU passthrough |
| 111 | LXC | `jellyfin-pve` | `192.168.50.243`, tail `100.111.70.79` | Jellyfin with Intel iGPU passthrough |
| 112 | LXC | `nas-pve` | `192.168.50.244` | NFS/Samba media export for VM 121 |
| 113 | LXC | `frigate-pve` | `192.168.50.245` | Frigate with Intel iGPU passthrough |
| 114 | LXC | `immich-pve` | `192.168.50.246` | Immich with iGPU/OpenVINO |
| 115 | LXC | `backup-pve` | `192.168.50.53` | Kopia backup server |

Removed guests:

- VM 100 `unraid`
- VM 120 `apps-docker-pve`

## Boot Order

```text
102 pulse         order=10, up=10
112 nas-pve       order=20, up=15
110 plex-pve      order=30, up=15
111 jellyfin-pve  order=40, up=15
113 frigate-pve   order=50, up=30
114 immich-pve    order=60, up=45
115 backup-pve    order=65, up=20
121 selfhost-pve  order=70, up=45
101 homelab-pve   order=80, up=30
```

`nas-pve` starts before consumers of the media export. `selfhost-pve` starts
after the app LXCs so Traefik and Homepage come up after their LAN backends.

## Storage

Configured Proxmox storage:

| Storage | Type | Backing path/dataset | Content |
|---|---|---|---|
| `local` | dir | `/var/lib/vz` | ISO, backups, templates, import |
| `local-zfs` | zfspool | `rpool/data` | rootdir, images |
| `fast-vm` | zfspool | `fast/vm` | VM/LXC root disks |
| `tank-backup` | dir | `/tank/pve-backups` | Proxmox guest backup archives |

Important ZFS datasets:

| Dataset | Purpose |
|---|---|
| `fast/vm` | Proxmox VM/LXC disks |
| `fast/immich-app` | Live Immich app data, mounted into CT 114 and CT 115 |
| `fast/selfhost-decom-20260501` | Read-only rollback copy of old selfhost/appdata |
| `fast/domains` | Old Unraid VM images, not referenced by Proxmox configs |
| `tank/media` | Media library |
| `tank/frigate` | Frigate dataset; recordings are under `tank/frigate/storage` |
| `tank/cache-import` | Migration cache/import staging data |
| `tank/pve-backups` | Proxmox `vzdump` archives |
| `tank/fast-backups` | Kopia local repository storage |

Deleted migration datasets:

- `fast/system`
- `fast/appdata`
- `fast/isos`
- `fast/homelab`

## LXC Mounts

```text
102 pulse:
  rootfs: local-zfs:subvol-102-disk-0,size=4G

110 plex-pve:
  /tank/media -> /data ro
  Plex app data is inside CT rootfs at /var/lib/plexmediaserver

111 jellyfin-pve:
  /tank/media -> /data ro
  Jellyfin app data is inside CT rootfs at /var/lib/jellyfin

112 nas-pve:
  /tank/media -> /shares/media

113 frigate-pve:
  /tank/frigate/storage -> /media/frigate
  Frigate config is inside CT rootfs at /config

114 immich-pve:
  /fast/immich-app -> /mnt/user/immich-app

115 backup-pve:
  /fast/immich-app -> /source/immich-app ro
  /tank/fast-backups -> /backups
```

There are no live PVE references to `/fast/selfhost`.

## NAS Export

`nas-pve` exports only media.

NFS:

```text
/shares        192.168.50.0/24 ro, fsid=0, crossmnt
/shares/media  192.168.50.121 rw
/shares/media  192.168.50.0/24 ro
```

Samba:

```text
[media]
path = /shares/media
read only = yes
valid users = @nas-users
```

VM 121 mounts only the media export:

```text
192.168.50.244:/media /mnt/user/media nfs4 rw,_netdev,nofail,x-systemd.automount,x-systemd.idle-timeout=600,vers=4.2 0 0
```

VM 121 no longer mounts `/mnt/user/frigate` or `/mnt/user/selfhost`.

## iGPU Consumers

The Intel iGPU is passed through to these LXCs:

```text
110 plex-pve
111 jellyfin-pve
113 frigate-pve
114 immich-pve
```

Common devices:

```text
/dev/dri/renderD128
/dev/dri/card0
```

## Public Routes

VM 121 Traefik routes local/LXC services:

| Public host | Backend |
|---|---|
| `plex.chienlt.com` | `http://192.168.50.242:32400` |
| `immich-server.chienlt.com` | `http://192.168.50.246:2283` |
| `frigate.chienlt.com` | `http://192.168.50.245:5000` |
| `homepage.chienlt.com` | Homepage container on VM 121 |

`jellyseerr.chienlt.com` is routed through the external `cle-viettel`
Traefik path to VM 121 tail IP `100.81.144.82:5056`.

## Source Of Truth

NixOS and Home Manager:

```text
/home/cle/Source/dotfiles/home-manager/.config/home-manager
```

Important flake outputs:

```bash
nixos-rebuild switch --flake .#selfhost-pve
nixos-rebuild switch --flake .#homelab-pve
home-manager switch --flake .#selfhost-pve
```

VM 121 app runtime:

```text
/srv/selfhost
```

`/srv/selfhost` is mutable runtime state. Do not commit it wholesale.
