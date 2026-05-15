# cle-pve Current State

Last verified: 2026-05-11.

## Host

| Item | Value |
|---|---|
| Hostname | `cle-pve` |
| LAN IP | `192.168.50.13` |
| Proxmox | `pve-manager/9.1.9` |
| Kernel | `6.17.13-6-pve` |
| Access | `ssh cle-pve` |
| UI | `https://192.168.50.13:8006` |
| Swap | 16G zram via `zram-swap.service`, `vm.swappiness=10` |

Host PCI passthrough is configured for the installed RTX 3060:

- UEFI boot through `proxmox-boot-tool`, Secure Boot disabled.
- Kernel command line includes `intel_iommu=on intel_iommu=sp_off iommu=pt`.
- `/etc/modules-load.d/vfio.conf` loads `vfio`, `vfio_iommu_type1`, and
  `vfio_pci`.
- `/etc/modprobe.d/blacklist-nvidia-host.conf` blacklists `nouveau` and
  NVIDIA host drivers so the RTX 3060 stays available for passthrough.
- `/etc/modprobe.d/vfio-pci-rtx3060.conf` binds `10de:2504` and `10de:228e`
  to `vfio-pci`.
- RTX 3060 GPU `0000:01:00.0` and HDMI audio `0000:01:00.1` are isolated
  together in IOMMU group 15 and both use `vfio-pci`.

## Guests

| ID | Type | Name | Address | Purpose |
|---:|---|---|---|---|
| 100 | VM | `windows11` | stopped; last DHCP `192.168.50.227` | Imported Windows 11 VM from old Unraid disk image |
| 101 | VM | `homelab-pve` | `192.168.50.130` | NixOS homelab host managed from dotfiles |
| 121 | VM | `selfhost-pve` | `192.168.50.121`, tail `100.81.144.82` | NixOS Docker host for selfhost stack, Homepage, Jellyseerr |
| 122 | VM | `bazzite-gaming` | `192.168.50.8`, tail `100.94.32.85` | Bazzite gaming VM with RTX 3060 passthrough |
| 102 | LXC | `pulse` | `192.168.50.18` | Pulse monitoring |
| 110 | LXC | `plex-pve` | `192.168.50.242` | Plex with Intel iGPU passthrough |
| 111 | LXC | `jellyfin-pve` | `192.168.50.243`, tail `100.111.70.79` | Jellyfin with Intel iGPU passthrough |
| 112 | LXC | `nas-pve` | `192.168.50.244` | NFS/Samba shared data export |
| 113 | LXC | `frigate-pve` | `192.168.50.245` | Frigate with Intel iGPU passthrough |
| 114 | LXC | `immich-pve` | `192.168.50.246` | Immich with iGPU/OpenVINO |
| 115 | LXC | `backup-pve` | `192.168.50.53` | Kopia backup server |
| 116 | LXC | `traefik-pve` | `192.168.50.247`, tail `100.112.33.84` | Traefik ingress |

Removed guests:

- VM 120 `apps-docker-pve`

## LXC Resource Limits

Current Proxmox LXC limits after tuning:

| ID | Name | Cores | Memory | Swap | Rootfs |
|---:|---|---:|---:|---:|---:|
| 102 | `pulse` | 1 | 1024M | 512M | 4G |
| 110 | `plex-pve` | 4 | 4096M | 1024M | 24G |
| 111 | `jellyfin-pve` | 2 | 2048M | 512M | 24G |
| 112 | `nas-pve` | 1 | 512M | 256M | 16G |
| 113 | `frigate-pve` | 4 | 4096M | 1024M | 24G |
| 114 | `immich-pve` | 6 | 4096M | 1024M | 32G |
| 115 | `backup-pve` | 2 | 1536M | 512M | 8G |
| 116 | `traefik-pve` | 2 | 1024M | 512M | 8G |

Rootfs sizes are ZFS-backed and not shrunk during tuning. Memory and CPU limits
are tuned conservatively from Proxmox day/week max usage, with extra headroom for
Plex, Frigate, Immich, and backup jobs.

## VM Swap

The NixOS VMs use in-guest zram swap from their dotfiles NixOS configs:

| VM | RAM | zram swap |
|---:|---:|---:|
| 101 `homelab-pve` | 8G | ~8G |
| 121 `selfhost-pve` | 8G | ~8G |

This is guest-local compressed swap. It does not create an NVMe swap partition
or swapfile.

VM 121 `selfhost-pve` has virtio balloon statistics enabled with the balloon
target equal to the full 8G allocation. This is for Proxmox memory reporting,
not for shrinking the VM below 8G during normal operation.

## Bazzite Gaming VM

VM 122 `bazzite-gaming` runs Bazzite with RTX 3060 passthrough:

| Item | Value |
|---|---|
| VMID | `122` |
| Guest hostname | `bazzite-gaming` |
| Guest IP | DHCP `192.168.50.8`, tail `100.94.32.85` |
| Tailscale | `bazzite-gaming.tail148f9.ts.net`, `tag:trusted`, Tailscale SSH enabled |
| Firmware / machine | OVMF, `pc-q35-10.1` |
| CPU | 8 vCPU, `host` |
| Memory | 8G dedicated, ballooning disabled |
| Boot disk | `fast-vm:vm-122-disk-1`, 128G, virtio-scsi, discard, SSD flag |
| EFI / TPM | `fast-vm` EFI disk with `pre-enrolled-keys=0`, TPM 2.0 state |
| Network | virtio on `vmbr0`, firewall enabled, MAC `BC:24:11:50:01:22` |
| VGA | none; RTX 3060 is the display path |
| Passthrough GPU | `hostpci0: 0000:01:00.0,pcie=1,x-vga=1` |
| Passthrough audio | `hostpci1: 0000:01:00.1,pcie=1` |
| CD-ROM | none; Bazzite ISO remains available in `local` ISO storage |
| Boot order | `scsi0` |
| Autostart | disabled |
| Protection | enabled |
| Tags | `bazzite,gaming` |
| Sunshine | `sunshine-beta`, web UI `https://192.168.50.8:47990` |

The installer ISO used for setup is the stable Bazzite NVIDIA Open live ISO for
newer NVIDIA cards. It is stored in Proxmox ISO storage but is not currently
attached to VM 122:

```text
local:iso/bazzite-nvidia-open-stable-live-amd64.iso
```

The ISO was downloaded and verified with SHA256:

```text
970a99236ee5d21c8826a0d853a5bd7da44f2d5c69782515eafb5db78338b110
```

The RTX 3060 is installed as GA106 LHR GPU `10de:2504` plus HDMI audio
`10de:228e`; both functions are in IOMMU group 15 and bound to `vfio-pci`.
Inside Bazzite, `nvidia-smi` confirms `NVIDIA GeForce RTX 3060`, driver
`595.71.05`, and 12G VRAM after a clean VM reboot. Key-based SSH from this
workstation uses `~/.ssh/id_ed25519_selfhost`.

The temporary virtio VGA fallback was removed after another clean reboot and
successful `nvidia-smi` check.

Sunshine runs as the `cle` user through the Homebrew-generated
`homebrew.sunshine-beta.service` user unit. The unit is enabled under
`graphical-session.target` rather than `default.target`, and Plasma autologin is
enabled for `cle` so Sunshine starts after a real Wayland desktop session exists.
An HDMI dummy plug is connected to the RTX 3060; Bazzite sees it as
`HDMI-A-1`/`Ugreen Group Ltd. UGREEN`. Sunshine is pinned to KWin screencast
capture with H.264 NVENC only:

```text
capture = kwin
encoder = nvenc
hevc_mode = 1
av1_mode = 1
origin_web_ui_allowed = lan
csrf_allowed_origins = https://192.168.50.8:47990,https://100.94.32.85:47990,https://bazzite-gaming.tail148f9.ts.net:47990,https://bazzite-gaming:47990
```

This avoids the NVIDIA/Homebrew HEVC capture failure observed as
`Couldn't import RGB Image: 00003009`. VM 122 has no custom `video=` kernel
argument for virtual display forcing. For Sunshine controller support, `cle` is
a member of local group `input`, and `/etc/tmpfiles.d/sunshine-uhid.conf` keeps
`/dev/uhid` owned by `root:input` with mode `0660`.

Tailscale is enabled through Bazzite's `ujust tailscale enable` recipe. The VM
joined the tailnet with a short-lived one-off `tag:trusted` auth key minted from
the Tailscale API, because the stored auth keys in `proxmox/.env` were stale.
Tailscale reports device ID `nUqhdKPAwk11CNTRL`, DNS name
`bazzite-gaming.tail148f9.ts.net`, tailnet IP `100.94.32.85`, Tailscale SSH
enabled, local operator `cle`, and key expiry disabled. OpenTofu does not yet
manage VM 122 or its Tailscale device lifecycle.

VM Secure Boot is disabled (`efidisk0` has `pre-enrolled-keys=0`) because
Bazzite failed to boot with `bad shim signature` before Universal Blue's Secure
Boot key was enrolled. Re-enable Secure Boot only after intentionally completing
Bazzite MOK enrollment. The original Secure Boot-enabled EFI vars disk was
removed after the non-Secure-Boot boot path was confirmed.

## Boot Order

```text
102 pulse         order=10, up=10
112 nas-pve       order=20, up=15
110 plex-pve      order=30, up=15
111 jellyfin-pve  order=40, up=15
113 frigate-pve   order=50, up=30
114 immich-pve    order=60, up=45
115 backup-pve    order=65, up=20
116 traefik-pve   order=68, up=15
121 selfhost-pve  order=70, up=45
101 homelab-pve   order=80, up=30
```

`nas-pve` starts before consumers of the media export. `traefik-pve` starts
after the app LXCs and before `selfhost-pve`; its file-provider routes to LXC
backends work before VM 121 starts, while Docker-backed VM 121 routes recover
after the selfhost VM and published app ports are online.
VM 100 `windows11` is intentionally stopped and not configured for host boot
autostart. VM 122 `bazzite-gaming` is intentionally not configured for host
boot autostart while the new gaming VM is still being validated.

## IaC

OpenTofu adoption has started under `proxmox/opentofu` in this repo. All current
LXCs, both NixOS VMs, VM 100 `windows11`, the Tailscale tailnet policy,
Tailscale DNS config, and stable Tailscale device tags/key-expiry/route settings
are now imported or managed and plan no changes. VM 122 `bazzite-gaming` is the
current exception and is pending adoption. The current Proxmox backup job,
storage definitions, and Proxmox APT repository enablement are also imported and
plan no changes. Current `chienlt.com` Cloudflare DNS records are imported and
plan no changes. The Pulse-created Proxmox monitoring role, user, and token
metadata are imported and plan no changes.

Local OpenTofu state on this workstation tracks the pre-existing active guests
plus the live Tailscale policy, DNS config, stable device settings, selected
route settings, platform settings, Cloudflare DNS records, and Pulse monitoring
identity metadata, then verified a no-op follow-up plan. VM 122
`bazzite-gaming` was created manually on 2026-05-10 and is pending OpenTofu
adoption after the final VM settings are settled. The state file and local token
env files are ignored by git.

A copy of the local state is backed up on `cle-pve`:

```text
/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-200900
/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260504-214447
/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260508-232851
```

Proxmox has user/token `opentofu@pve!cle-pve-adopt` for this adoption layer.
The user has `PVEAuditor` plus custom role `OpenTofuAdoptDisk` containing only
`VM.Config.Disk`.

Each tightened LXC has a CT-scoped role with `VM.Audit,VM.Config.Options`.
CT 102 `OpenTofuPulseManage` also includes `VM.Config.Memory` so OpenTofu can
adjust the Pulse LXC memory limit:

| CT | Role |
|---:|---|
| 102 | `OpenTofuPulseManage` |
| 110 | `OpenTofuPlexManage` |
| 111 | `OpenTofuJellyfinManage` |
| 112 | `OpenTofuNasManage` |
| 113 | `OpenTofuFrigateManage` |
| 114 | `OpenTofuImmichManage` |
| 115 | `OpenTofuBackupManage` |
| 116 | `OpenTofuTraefikManage` |

VM 101 has VM-scoped role `OpenTofuHomelabManage` with
`VM.Audit,VM.Config.Disk,VM.Config.Options,VM.GuestAgent.Audit`. It does not
include `VM.PowerMgmt`, so the OpenTofu token cannot shut down or restart
`homelab-pve`.

VM 121 has VM-scoped role `OpenTofuSelfhostManage` with
`VM.Audit,VM.Config.Disk,VM.Config.Memory,VM.Config.Options,VM.GuestAgent.Audit`.
It does not include `VM.PowerMgmt`, so the OpenTofu token cannot shut down or
restart `selfhost-pve`.

VM 100 has VM-scoped role `OpenTofuWindowsManage` with
`VM.Allocate,VM.Audit,VM.Config.CDROM,VM.Config.CPU,VM.Config.Disk`,
`VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options`, and
`VM.GuestAgent.Audit,VM.PowerMgmt`. OpenTofu can start and stop VM 100; the
desired state is currently stopped.

OpenTofu has Windows-import storage role `OpenTofuWindowsStorage` with
`Datastore.Audit,Datastore.AllocateSpace` on `/storage/local` and
`/storage/fast-vm`, and network role `OpenTofuWindowsNetwork` with `SDN.Use` on
`/sdn/zones/localnetwork/vmbr0`.

OpenTofu also has storage-scoped role `OpenTofuStorageManage` with
`Datastore.Allocate,Datastore.Audit` on:

```text
/storage/local
/storage/local-zfs
/storage/fast-vm
/storage/tank-backup
```

The provider requires `Datastore.Allocate` even to read/import those storage
resources.

OpenTofu also has identity-scoped role `OpenTofuIdentityManage` with
`User.Modify` on `/access` so the provider can refresh imported Proxmox
user-token metadata. It does not include `Permissions.Modify`, so routine
OpenTofu runs cannot change cluster ACL bindings.

OpenTofu imports the Pulse monitoring identity:

```text
PulseMonitor role
pulse-monitor@pam user
pulse-monitor@pam!pulse-cle-pve-192-168-50-18 token metadata
```

The live Pulse ACLs are documented in `proxmox/opentofu/identity.tf`, but ACL
changes are ignored because applying them would require `Permissions.Modify` on
`/`.

OpenTofu manages the full Tailscale policy from
`proxmox/opentofu/tailscale-policy.hujson`. Manual ACL edits in the Tailscale
admin console or API will drift until copied back into that file.

Tailscale `group:media-guests` currently contains
`nguyenphuongthao9497@gmail.com`. It grants HTTPS access to CT 116
`traefik-pve` for Frigate and media services, direct Jellyfin tailnet service access, plus
Tailscale SSH access to tagged servers:

```text
traefik-pve:443
100.112.33.84:443
jellyfin-pve:8096
100.111.70.79:8096
tag:server:22
tag:trusted:22
```

The same policy tests deny other direct media backend ports, Dozzle/app ports
on `jellyfin-pve`, and NAS/NFS access for `group:media-guests`. Tailscale ACLs
are host-and-port based, so hostname separation for services behind
`traefik-pve:443` must come from Traefik or the applications themselves.
Tailscale SSH authorization is separately tested with `sshTests`.

OpenTofu also manages Tailscale DNS as a full tailnet DNS resource:

```text
MagicDNS: true
Override local DNS: true
Nameservers: 100.107.99.32, 100.79.39.73, 1.1.1.1
Search paths: none
```

The current stable Tailscale device tag/key-expiry resources cover
`cle_viettel`, `homelab_pve`, `jellyfin_pve`, `n100`, `nas_pve`, `oracle`,
`pulse_pve`, `selfhost_pve`, and `traefik_pve`.

OpenTofu also manages selected Tailscale route enablement:

```text
cle_viettel: 0.0.0.0/0, ::/0
oracle: 0.0.0.0/0, ::/0
n100: none enabled
```

Route advertisement on each host is still configured by the host Tailscale
runtime, not OpenTofu.

The OpenTofu-managed policy grants `cle-viettel-vpn` only the service ports it
needs for external media ingress:

```text
jellyfin-pve:8096
selfhost-pve:5056
selfhost-pve:6767
```

Policy tests deny `cle-viettel-vpn` access to Jellyfin SSH, Dozzle agent, and
other non-service ports.

The OpenTofu-managed policy also grants `oracle` access to `traefik-pve:443`
so the Hermes gateway can reach Traefik-hosted Arr APIs such as Radarr, Sonarr,
and Prowlarr. It also grants `oracle` access to `nas-pve:2049` so Hermes can
mount the shared zk notebook. Policy tests keep direct VM 121 SSH, direct VM 121
HTTPS, and direct Arr backend ports denied from `oracle`.

OpenTofu manages the Proxmox backup job `nightly-guests`, the storage
definitions `local`, `local-zfs`, `fast-vm`, and `tank-backup`, and Proxmox APT
repository enablement for `no-subscription`, `enterprise`, `test`, and
`ceph-squid-enterprise`. It also imports the Pulse monitoring role, user, and
token metadata.

OpenTofu also manages current `chienlt.com` Cloudflare DNS records:

```text
*.chienlt.com -> 100.112.33.84
chienlt.com -> 100.104.100.77
adguard.chienlt.com -> 100.107.99.32
adguard-oracle.chienlt.com -> 168.138.176.219
bazarr.chienlt.com -> 171.244.62.91
jellyfin.chienlt.com -> 171.244.62.91
jellyseerr.chienlt.com -> 171.244.62.91
plex.chienlt.com -> 100.112.33.84
amz.chienlt.com -> 9315ec0b-64d4-4744-a743-7bb0c2e35e45.cfargotunnel.com
```

Direct tailnet records are unproxied because Cloudflare cannot proxy private
Tailscale `100.x` addresses.

OpenTofu does not yet enforce ZFS datasets, host package installation, system
services, zram/sysctl, app config, host-level service wiring, or Tailscale
device lifecycle/auth-key/device-authorization workflows. Current LXC bind
mounts and device passthrough are represented in OpenTofu and plan cleanly.

Targeted ignores remain for LXC `operating_system[0].template_file_id`, because
the provider requires a template for create but imported containers do not keep
that template in live state. CT 102 also ignores the noisy community-script HTML
description.

Targeted VM ignores remain:

- `disk[0].path_in_datastore`, because that is provider/import metadata for the
  existing disk rather than desired configuration.
- VM 121 `description`, because the live NixOS-generated description includes a
  leading space.
- VM 121 `keyboard_layout` and `agent[0].type`, because normalizing those
  provider defaults previously caused the provider to request VM shutdown.

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
| `fast/zk` | Shared zk notebook data, exported by CT 112 and backed up by CT 115 |
| `fast/selfhost-decom-20260501` | Read-only rollback copy of old selfhost/appdata |
| `fast/domains` | Old Unraid VM images; `Windows11/vdisk1.img` was imported into VM 100 |
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
  /fast/zk -> /shares/zk
  /dev/net/tun passthrough for Tailscale

113 frigate-pve:
  /tank/frigate/storage -> /media/frigate
  Frigate config is inside CT rootfs at /config

114 immich-pve:
  /fast/immich-app -> /mnt/user/immich-app

115 backup-pve:
  /fast/immich-app -> /source/immich-app ro
  /fast/zk -> /source/zk ro
  /tank/fast-backups -> /backups

116 traefik-pve:
  rootfs: fast-vm:subvol-116-disk-0,size=8G
  /dev/net/tun passthrough for Tailscale
  Traefik runtime state is inside CT rootfs at /srv/traefik
```

There are no live PVE references to `/fast/selfhost`.

## NAS Export

`nas-pve` exports media and the shared zk notebook.

NFS:

```text
/shares        192.168.50.0/24 ro, fsid=0, crossmnt
/shares/media  192.168.50.121 rw
/shares/media  192.168.50.0/24 ro
/shares/zk     192.168.50.55 rw
/shares/zk     192.168.50.130 rw
/shares/zk     192.168.50.121 rw
/shares/zk     100.79.39.73 rw, all_squash, anonuid=1000, anongid=100
```

Samba:

```text
[media]
path = /shares/media
read only = yes
valid users = @nas-users

[zk]
path = /shares/zk
read only = no
valid users = @nas-users
```

VM 121 mounts media and zk from `nas-pve`; VM 101 and `nixos-cle` mount zk
from `nas-pve`. Oracle mounts zk over Tailscale for Hermes:

```text
192.168.50.244:/media /mnt/user/media nfs4 rw,_netdev,nofail,x-systemd.automount,x-systemd.idle-timeout=0,vers=4.2 0 0
192.168.50.244:/zk /srv/selfhost/zk nfs4 rw,_netdev,nofail,x-systemd.automount,x-systemd.idle-timeout=0,vers=4.2 0 0
nas-pve:/zk /home/hermes/zk nfs4 rw,_netdev,nofail,x-systemd.automount,x-systemd.idle-timeout=0,x-systemd.after=tailscaled.service,x-systemd.requires=tailscaled.service,vers=4.2,proto=tcp 0 0
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

Frigate CT 113 currently uses the iGPU for detect/decode paths and only
transcodes main streams through go2rtc when an explicit main/live stream needs
H.264 output. Recording inputs use go2rtc aliases that copy the camera video
stream instead of forcing always-on VAAPI transcodes; the Frigate live view
prefers camera substreams first.

On 2026-05-05, retained logs showed one Intel `i915` GPU hang at
`07:58:23`, correlated with a go2rtc VAAPI transcode timeout. The saved host
error dump is `/root/i915-error-2026-05-05-113802.txt` on `cle-pve`.

Frigate may log `Unable to poll intel GPU stats: Failed to initialize PMU!
(Permission denied)`. This is expected with the host kernel setting
`kernel.perf_event_paranoid=4` and does not block video decoding or recording.
Lowering it to `0` would make Frigate's internal Intel GPU stats work from the
unprivileged LXC/container, but it is a host-wide perf/PMU permission relaxation
and is intentionally not applied.

## Public Routes

CT 116 `traefik-pve` runs Traefik from `/srv/traefik/docker-compose.yml` with
only `web` on `80/tcp`, `websecure` on `443/tcp`, the file provider, and the
Cloudflare DNS ACME resolver. It is also on Tailscale as
`traefik-pve.tail148f9.ts.net`, tagged `tag:trusted`, with tailnet address
`100.112.33.84`.

File-provider routes on `traefik-pve` route local/LXC services directly:

| Public host | Backend |
|---|---|
| `proxmox.chienlt.com` | `https://192.168.50.13:8006` |
| `plex.chienlt.com` | `http://192.168.50.242:32400` |
| `immich-server.chienlt.com` | `http://192.168.50.246:2283` |
| `frigate.chienlt.com` | `http://192.168.50.245:5000` |
| `kopia.chienlt.com` | `http://192.168.50.53:51515` |
| `bambuddy.chienlt.com` | `http://100.107.253.59:8000` |
| `pulse.chienlt.com` | `http://192.168.50.18:7655` |

Docker-backed services on VM 121 are exposed to `traefik-pve` through direct
host-bound Docker port publishes on LAN IP `192.168.50.121`. These high ports
are intentionally bound to the LAN address rather than all interfaces. The old
temporary `selfhost-route-bridge` nginx container has been stopped, removed,
and archived at `/srv/selfhost/traefik-bridge.decom-20260508`.

The old VM 121 Traefik container is stopped. Its service remains in
`/srv/selfhost/docker-compose.yml` only behind the explicit `old-traefik`
profile, so normal `docker compose up -d` does not restart it. The runtime
backup from the profile change is
`/srv/selfhost/docker-compose.yml.bak-traefik-lxc-20260508`.

Important Docker-backed Traefik routes:

| Public host | Backend |
|---|---|
| `homepage.chienlt.com` | `http://192.168.50.121:13000` |
| `dozzle.chienlt.com` | `http://192.168.50.121:13001` |
| `sonarr.chienlt.com` | `http://192.168.50.121:13002` |
| `radarr.chienlt.com` | `http://192.168.50.121:13003` |
| `prowlarr.chienlt.com` | `http://192.168.50.121:13004` |
| `sabnzbd.chienlt.com` | `http://192.168.50.121:13005` |
| `qbittorrent.chienlt.com` | `http://192.168.50.121:13006` |
| `tautulli.chienlt.com` | `http://192.168.50.121:13007` |
| `reclaimerr.chienlt.com` | `http://192.168.50.121:13008` |
| `dockge.chienlt.com` | `http://192.168.50.121:13009` |
| `filebrowser.chienlt.com` | `http://192.168.50.121:13010` |
| `silverbullet.chienlt.com` | `http://192.168.50.121:13011` |
| `speedtest-tracker.chienlt.com` | `http://192.168.50.121:13012` |
| `dockhand.chienlt.com` | `http://192.168.50.121:13013` |
| `hledger-webapp.chienlt.com` | `http://192.168.50.121:13014` |
| `openspeedtest.chienlt.com` | `http://192.168.50.121:13015` |
| `bazarr.chienlt.com` | `http://192.168.50.121:13016` |
| `syncthing.chienlt.com` | `http://192.168.50.121:13017` |
| `seerr.chienlt.com`, `jellyseerr.chienlt.com` | `http://192.168.50.121:13018` |
| `watchstate.chienlt.com` | `http://192.168.50.121:13019` |

Pulse local password auth is disabled on CT 102. CT 116 Traefik injects Pulse
proxy-auth headers for `pulse.chienlt.com`, so the UI opens as proxy user
`cle`. Direct backend or tailnet access can load the UI shell, but
authenticated API calls are not proxy-authenticated without the Traefik headers.
Pulse API token auth remains enabled for agents.

CT 102 runs Pulse server `v6.0.0-rc.4` on the `rc` update channel, with
unattended auto-updates disabled. `/bin/update` is the Pulse
installer-managed helper for manual server updates.

CT 102 also runs Tailscale `1.96.4` as `pulse-pve.tail148f9.ts.net`, tagged
`tag:server`, with tailnet address `100.86.86.121`. The LXC has
`/dev/net/tun` passthrough so Tailscale runs in normal tunnel mode. Tailscale
tags and key-expiry settings for `pulse_pve` are imported into OpenTofu.

Pulse alert notifications are active. CT 102 stores the enabled `Telegram
Alerts` webhook encrypted at `/etc/pulse/webhooks.enc`; the Telegram bot token
and chat ID are sourced from local `.env.local` during setup and are not stored
in the repo. Pulse v6 host-agent SMART disk temperature alerts are configured
through `agentDefaults.diskTemperature` and trigger at `65 C`, clearing at
`60 C`.

Pulse alert delivery has a 15-minute cooldown and flapping protection enabled
with a 5-minute window, 5 state changes to detect flapping, and a 15-minute
flapping cooldown. Docker image update alerts fire only after an available
update has persisted for 72 hours. Resource overrides suppress intentional
powered-off/connectivity alerts for VM 100 `windows11` and VM 122
`bazzite-gaming`; `cle-viettel` host memory alerts use `90/85%` under raw host
ID override key `cf46a880-112a-44d7-819b-520e81355e49` because Pulse
`v6.0.0-rc.4` host-agent threshold resolution does not apply the prefixed
`agent:` alert resource key. `cle-pve` node memory alerts use `98/90%` and a
15-minute per-metric duration via `metricTimeThresholds.node.memory = 900`.
CT 110 `plex-pve` CPU alerts use `95/90%` under the normalized Pulse override key
`guest:pve-192.168.50.13:110`, so normal Plex transcode bursts do not page at
the default guest CPU threshold.

`cle-pve` runs `pulse-agent.service` from `/usr/local/bin/pulse-agent`, pointing
at `http://192.168.50.18:7655` with host metrics enabled, Docker/Kubernetes
disabled, and Proxmox mode enabled for PVE. The agent token is stored root-only
at `/var/lib/pulse-agent/token`.

Docker-running LXCs run containerized Pulse agents from
`/opt/pulse-agent/docker-compose.yml`, using `rcourtman/pulse:5.1` with the
bundled `/opt/pulse/bin/pulse-agent-linux-amd64` binary. These agents mount the
local Docker socket, disable host/Kubernetes/Proxmox collection, disable agent
auto-update, and report Docker only to `http://192.168.50.18:7655`.

```text
110 plex-pve     agent-id plex-pve-docker
111 jellyfin-pve agent-id jellyfin-pve-docker
113 frigate-pve  agent-id frigate-pve-docker
114 immich-pve   agent-id immich-pve-docker
```

VM 121 `selfhost-pve` also runs a containerized Pulse Docker agent as service
`pulse-agent` in `/srv/selfhost/docker-compose.yml`. It uses the same Pulse
image and Docker-only flags, with agent ID `selfhost-pve-docker`.

N100 runs a rootless Pulse Podman agent under Linux user `cle` as
`~/.config/systemd/user/pulse-agent.service`. It uses
`~/.local/bin/pulse-agent`, reads its token from `~/.config/pulse-agent/token`,
and talks only to the rootless Podman socket at
`/run/user/1000/podman/podman.sock`. Host and Podman/Docker collection are
enabled; Kubernetes and Proxmox collection are disabled. Pulse lists it as
hostname `n100` in Hosts and as agent ID `n100-podman` in Docker hosts.

Remote tailnet hosts run Pulse `v5.1.29` agents as root systemd services,
pointing at the Pulse LXC tailnet endpoint `http://100.86.86.121:7655`. Their
tokens are stored root-only at `/var/lib/pulse-agent/token`, auto-update and
command execution are disabled, and the local health listener is bound to
`127.0.0.1:9191`.

```text
cle-viettel-vpn  hostname cle-viettel   agent-id cle-viettel-docker  host + Docker
cle-cloudfly     hostname cle-cloudfly  agent-id cle-cloudfly-host   host only
oracle           hostname oracle        agent-id oracle-host         host only
```

The OpenTofu-managed Tailscale policy allows only these three hosts to reach
`pulse-pve:7655` for agent reporting. It does not grant SSH, HTTPS, or other
Pulse LXC ports.

`oracle` also runs the Hermes gateway as the dedicated `hermes` user under
`hermes-gateway.service`. Arr stack runtime credentials for Hermes are stored
only on Oracle in `/home/hermes/.hermes/arr-stack.env` and loaded through a
systemd user drop-in; the gateway config allows those env names through
`terminal.env_passthrough`. Oracle mounts the shared zk notebook read-write at
`/home/hermes/zk`; `nas-pve` maps Oracle NFS writes to UID `1000` and GID `100`
so Hermes can edit the existing notebook files without changing their ownership
model.

`oracle` also runs Uptime Kuma v2 as user `ubuntu` through the rootless Podman
Quadlet `~/.config/containers/systemd/uptime-kuma.container`, generated as
`uptime-kuma.service`. The UI is Tailscale-only at
`http://100.79.39.73:3001`. Declarative monitors live in
`/home/ubuntu/Source/selfhost/uptime-kuma/monitors.yaml` and are applied by
`setup_monitors.py` with credentials from the runtime `.env`, which is not
tracked here. Kuma includes TCP port monitors for AdGuard DNS on
`oracle:53` and `cle-viettel-vpn:53`. The Frigate HTTP monitor remains
configured but inactive because `https://frigate.chienlt.com/api/health`
currently returns HTTP 404.

Each Docker Pulse agent has a separate API token with `docker:report`,
`host-agent:config:read`, and `host-agent:report` scopes. The compose
healthcheck is disabled because the public Pulse image carries the server
healthcheck, while these containers run only the agent binary.
Remote host-only agents use separate tokens with only `host-agent:report` and
`host-agent:config:read`; `cle-viettel` additionally has `docker:report`.

```text
LXC tokens:          /opt/pulse-agent/token
selfhost-pve token:  /srv/selfhost/pulse-agent/token
N100 token:          ~/.config/pulse-agent/token
remote host tokens:  /var/lib/pulse-agent/token
```

VM 121 also runs the central Dozzle UI in `/srv/selfhost/docker-compose.yml`.
It reads VM 121's local Docker socket and connects to Dozzle agents running on
the Docker LXCs. The LXC agents run from
`/opt/dozzle-agent/docker-compose.yml`, mount only the local Docker socket
read-only, and expose Dozzle agent port `7007` on the LAN:

```text
192.168.50.242:7007 plex-pve
192.168.50.243:7007 jellyfin-pve
192.168.50.245:7007 frigate-pve
192.168.50.246:7007 immich-pve
```

The central Dozzle container uses `DOZZLE_REMOTE_AGENT` with friendly host names
and group `PVE LXCs`. The remote agents are not published through Traefik.

Pulse now monitors Proxmox through dedicated token auth:

```text
pulse-monitor@pam!pulse-cle-pve-192-168-50-18
```

The old `root@pam` password-backed Pulse node config has been replaced. The
`pulse-monitor@pam` user has `PVEAuditor`, custom `PulseMonitor`, and
`PVEDatastoreAdmin` on `/storage` for monitoring, guest-agent/storage visibility,
and backup visibility.

These routes are served by the external `cle-viettel` Traefik path over
Tailscale:

| Public host | Backend |
|---|---|
| `jellyfin.chienlt.com` | `http://100.111.70.79:8096` |
| `jellyseerr.chienlt.com` | `http://100.81.144.82:5056` |
| `bazarr.chienlt.com` | `http://100.81.144.82:6767` |
| `timthuoc.chienlt.com` | `http://100.67.251.63:8501` |

The OpenTofu-managed tailnet policy grants `cle-viettel-vpn` only the required
Jellyfin and VM 121 media ports. `timthuoc.chienlt.com` currently resolves to a
tailnet address, not the public VPS IP.

`cle-viettel` hardening as of 2026-05-04:

- Ubuntu packages are current with kernel `5.15.0-177-generic`, Tailscale
  `1.96.4`, and Docker Engine `29.4.2`.
- Traefik publishes only public `80/tcp` and `443/tcp`; the insecure dashboard
  API is disabled with `--api.insecure=false`, and `8080/tcp` is not published.
- `adguard.chienlt.com` resolves to the `cle-viettel` Tailscale address
  `100.107.99.32`. Traefik serves it through `adguard-rtr` with
  `adguard-tailnet-chain`, which allowlists Tailscale source addresses plus the
  local Docker gateway source observed for tailnet HTTPS, applies the CrowdSec
  bouncer, and adds basic security headers. The backend is
  `http://100.107.99.32:82`; forced public-IP requests with the AdGuard host
  header return HTTP 403.
- AdGuard Home persistent clients are maintained from current Tailscale
  MagicDNS names and `100.x` addresses. As of the latest sync, the UI reports 16
  persistent clients: `apple-tv`, `aws-urieljsc`, `cle-cloudfly`,
  `cle-viettel-vpn`, `homelab-pve`, `ipad161`, `iphone-15`, `iphone184`,
  `jellyfin-pve`, `les-laptop`, `n100-do4vk2q3njq`, `oracle`, `pulse-pve`,
  `selfhost-pve`, `unraid-cle`, and `unraid-w11`.
- `docker-user-firewall.service` installs a persistent `DOCKER-USER` guard
  chain that allows Docker-published public traffic from `eth0` only to
  `80/tcp` and `443/tcp`, then drops other Docker-published public ports.
- `homiix-app` may still show a Docker listener on `0.0.0.0:8000`, but public
  `eth0` access is blocked by the `DOCKER-USER` guard.
- `homiix-app` is manually run on Docker network `homiix-net` with restart
  policy `unless-stopped` and a Python-based Docker healthcheck against
  `http://127.0.0.1:8000/`. The image's original `curl` healthcheck is not used
  because the image does not include `curl`.
- Runtime Traefik and monitoring compose files keep secrets in root-only `.env`
  files instead of literal compose environment values.
- CrowdSec `1.7.7` runs as a system service. Its Traefik acquisition file is
  `/etc/crowdsec/acquis.d/traefik.yaml`, reading
  `/root/Source/traefik/logs/access.log` with `type: traefik`, and the
  `crowdsecurity/traefik` collection is installed.
- CrowdSec LAPI listens on `0.0.0.0:8080` for the Traefik container. UFW allows
  `172.21.0.0/16` to reach `8080/tcp` and denies public `8080/tcp`; public
  `171.244.62.91:8080` times out.
- Traefik uses the
  `github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin` CrowdSec bouncer
  plugin. The `traefik-media` bouncer key is stored root-only at
  `/root/Source/traefik/crowdsec/bouncer-key`.
- Bazarr, Jellyfin, Jellyseerr, and Plex routers use `media-public-chain`, which
  applies the CrowdSec bouncer, a `600/minute` rate limit with `300` burst, and
  basic security headers. `timthuoc.chienlt.com` is intentionally outside this
  media chain.

## VM 121 Runtime Integrations

WatchState runs in the VM 121 Docker stack as container `watchstate`, using
image `ghcr.io/arabcoders/watchstate:latest`. It is published only on LAN-bound
host port `192.168.50.121:13019` and is exposed publicly through CT 116 Traefik
as `watchstate.chienlt.com`. Its persisted runtime data lives under
`/srv/selfhost/watchstate`; Plex/Jellyfin tokens and identities are configured
through the WatchState UI and are not committed.

The WatchState `main` identity has single-user backends `plex_main` and
`jellyfin_main`, pointing to Plex LXC `192.168.50.242:32400` and Jellyfin LXC
`192.168.50.243:8096`. Import and export are enabled on both backends for
two-way sync. The initial full import completed with no failed items and
populated the local WatchState database with 873 history rows.

WatchState's persisted environment has `WS_TZ=Asia/Ho_Chi_Minh`,
`WS_CRON_IMPORT=true`, and `WS_CRON_EXPORT=true`. The VM 121 Docker Compose
service also exports `TZ=Asia/Ho_Chi_Minh` and `WS_TZ=Asia/Ho_Chi_Minh`, so
the scheduler displays local `+07` next-run times. The scheduler runs import
hourly at `0 */1 * * *` and export hourly at `30 */1 * * *`. A permanent
WatchState backup of Jellyfin play state was written to
`/srv/selfhost/watchstate/backup/main.jellyfin_main.json.zip` before the first
Jellyfin export. A config backup was written to
`/srv/selfhost/watchstate-config-backup-two-way-20260511-124843.tgz` before
enabling two-way export. Manual dry-run and real baseline exports made
comparison requests and found no play-state changes to apply.

Reclaimerr runs in the VM 121 Docker stack. Its service connection settings live
in the runtime SQLite database at
`/srv/selfhost/reclaimerr/data/database/reclaimerr.db`.

Current Reclaimerr media service endpoints:

| Service | Endpoint |
|---|---|
| Jellyfin | `http://192.168.50.243:8096` |
| Plex | `http://192.168.50.242:32400` |
| Radarr | `http://radarr:7878` |
| Sonarr | `http://sonarr:8989` |
| Seerr | `http://seerr:5055` |

## Homepage

Homepage live config:

```text
/srv/selfhost/homepage/config/services.yaml
/srv/selfhost/homepage/config/widgets.yaml
```

`services.yaml` includes the daily service groups plus curated
`Infrastructure` and `Internal Tools` groups. The added infrastructure/admin
coverage includes Proxmox, Pulse, Kopia, router admin links, Prefect,
Silverbullet, Playwright MCP, Chrome DevTools, Tailscale MCP, FlareSolverr,
Docker Socket Proxy, Oracle Hermes, WatchState, Bambuddy, TRMNL BYOS, Matter
Server, HA MCP, and Bambuddy's Obico ML status endpoint.

The Homepage container mounts VM 121 `/mnt/user/media` read-only as
`/storage/media`. `widgets.yaml` includes a `Media Storage` resources widget
for `/storage/media`, so Homepage shows the same media filesystem capacity that
Sonarr and Radarr see through their `/data` mount.

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
