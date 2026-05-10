# cle-pve Infrastructure Changelog

## 2026-05-10

- Added CT 115 `backup-pve` read-only access to `/fast/zk` at `/source/zk` and
  added a Kopia policy for `root@backup-pve:/source/zk`, so the shared zk
  notebook is covered by the local Kopia repository.
- Upgraded CT 102 `pulse` from Pulse `v5.1.30` stable to `v6.0.0-rc.4` on
  the `rc` update channel, with unattended auto-updates still disabled. The
  initial signed installer path failed release signature verification before
  replacing the binary; the successful run used the official RC4 Linux amd64
  archive after matching its published SHA256. Runtime config backups were
  written as `/etc/pulse.backup.20260510-180010` and
  `/etc/pulse.backup.20260510-180150`.
- Replaced CT 102's legacy Community Scripts `/bin/update` wrapper with the
  Pulse installer-managed update helper. Verified `pulse.service` active,
  internal `/api/health`, and public `https://pulse.chienlt.com/api/version`,
  `/api/monitoring/scheduler/health`, and `/api/resources` through Traefik.
  Existing Pulse agents remain on their prior versions for now.

## 2026-05-09

- Updated VM 121 live Homepage config so the Traefik card no longer references
  the stopped VM 121 Docker Traefik container or unavailable dashboard widget.
  It now monitors the CT 116 `traefik-pve` ingress path through
  `https://frigate.chienlt.com/api/version`. The runtime backup is
  `/srv/selfhost/homepage/config/services.yaml.bak-traefik-lxc-card-20260509`.
- Removed the stale Tdarr card from VM 121 live Homepage config and corrected
  the AdGuard cards. `AdGuard Home (Viettel)` monitors
  `100.107.99.32:82`, and `AdGuard Home (Oracle)` keeps the working
  tailnet-only `100.79.39.73:81` endpoint. The runtime backup is
  `/srv/selfhost/homepage/config/services.yaml.bak-tdarr-adguard-20260509`.

## 2026-05-08

- Created CT 116 `traefik-pve` at `192.168.50.247`, installed Docker Engine
  with the Compose plugin plus Tailscale, joined it as tagged tailnet node
  `traefik-pve` (`100.112.33.84`), copied the existing Traefik rules and ACME
  state, and started a file-provider-only Traefik instance on ports `80/443`.
- Added VM 121 runtime bridge container `selfhost-route-bridge` under
  `/srv/selfhost/traefik-bridge`, publishing LAN-only ports
  `192.168.50.121:13000-13018` for Docker-backed routes now that Traefik no
  longer shares VM 121's Docker network. Verified forced-resolution HTTPS
  checks for Frigate, Homepage, Dozzle, Sonarr, Radarr, Immich, Proxmox, and
  Pulse through the new LXC.
- Replaced the temporary VM 121 route bridge with direct LAN-bound Docker port
  publishes on the app containers themselves, keeping the same
  `192.168.50.121:13000-13018` backend URLs for Traefik. Stopped and removed
  `selfhost-route-bridge`, archived its runtime directory to
  `/srv/selfhost/traefik-bridge.decom-20260508`, and backed up the edited VM
  121 compose file to
  `/srv/selfhost/docker-compose.yml.bak-direct-published-routes-20260508`.
- Stopped the old VM 121 Traefik container and put its compose service behind
  the explicit `old-traefik` profile so a normal `docker compose up -d` on
  `/srv/selfhost` does not restart it. The VM 121 runtime compose backup is
  `/srv/selfhost/docker-compose.yml.bak-traefik-lxc-20260508`.
- Updated OpenTofu inventory, Tailscale policy/device metadata, and Cloudflare
  DNS intent so `*.chienlt.com` and `plex.chienlt.com` point to
  `traefik-pve`'s Tailscale IP, with `oracle` and `group:media-guests` granted
  HTTPS to `traefik-pve:443` instead of VM 121 Traefik. Backed up local
  OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260508-232851`
  before applying; the follow-up plan was no-op.
- Moved the shared zk notebook from VM 121 root storage to the Proxmox fast
  dataset `fast/zk`, bind-mounted it into CT 112 `nas-pve` at `/shares/zk`,
  and exported it as NFSv4 path `/zk` for `nixos-cle`, `homelab-pve`, and
  `selfhost-pve`.
- Updated NixOS/Home Manager consumers to use `/srv/selfhost/zk` as the shared
  notebook path.

## 2026-05-07

- Checked Uptime Kuma on `oracle`: the rootless Podman Quadlet
  `uptime-kuma.service` is active and published on `3001/tcp`. Added
  declarative `port` monitor support to Oracle's runtime
  `/home/ubuntu/Source/selfhost/uptime-kuma/setup_monitors.py` and provisioned
  two Kuma monitors for AdGuard DNS on `oracle:53` and
  `cle-viettel-vpn:53`. Runtime backups were written beside the edited files as
  `setup_monitors.py.bak-20260507-adguard-port` and
  `monitors.yaml.bak-20260507-adguard-port`.
- Disabled the existing Frigate Uptime Kuma HTTP monitor after it repeatedly
  returned HTTP 404 from `https://frigate.chienlt.com/api/health`. Oracle's
  runtime `monitors.yaml` now marks it `active: false`, and
  `setup_monitors.py` now honors `active: false` by pausing existing monitors.
  Runtime backups were written as `monitors.yaml.bak-20260507-disable-frigate`
  and `setup_monitors.py.bak-20260507-disable-frigate`.

## 2026-05-05

- Added a narrow OpenTofu-managed Tailscale grant for `oracle` to reach
  `selfhost-pve:443` so the Oracle Hermes gateway can call VM 121
  Traefik-hosted Arr APIs. Policy tests keep direct VM 121 SSH and direct Arr
  backend ports denied from `oracle`.
- Added Oracle Hermes runtime Arr stack credentials through
  `/home/hermes/.hermes/arr-stack.env`, loaded by a
  `hermes-gateway.service` systemd user drop-in and exposed to Hermes tools via
  `terminal.env_passthrough`. Secret values remain runtime-only and untracked.
- Reviewed the CT 113 `frigate-pve` Intel iGPU hang and Frigate/go2rtc setup.
  Retained host logs showed one `i915` GPU hang at `07:58:23`, correlated with
  a go2rtc VAAPI transcode timeout; the host error dump was saved at
  `/root/i915-error-2026-05-05-113802.txt`.
- Reduced Frigate go2rtc iGPU pressure by changing Tapo recording inputs to
  go2rtc record aliases that copy camera video instead of forcing always-on
  VAAPI H.264 transcodes, preferring camera substreams for live views, and
  keeping main-stream VAAPI transcodes only for explicit main/live viewing.
- Left host `kernel.perf_event_paranoid=4` in place after evaluating the
  Frigate PMU stats warning. Lowering it to `0` would fix Frigate's internal
  Intel GPU stats polling from the unprivileged LXC/container, but it is a
  host-wide perf/PMU permission relaxation; the warning is cosmetic for
  decoding and recording.
- Decommissioned the obsolete rootless Podman monitoring stack on `oracle`:
  Beszel hub, Prometheus, and Grafana. Their Quadlet sources were archived
  outside the generator path at
  `/home/ubuntu/.local/share/decommissioned-containers/20260505/`, their
  containers were removed, and their host data directories were preserved under
  `/home/ubuntu/Source/selfhost/`. The separate `beszel-agent.service` system
  unit was stopped, disabled, and archived under
  `/etc/systemd/system/decommissioned-20260505/`. Uptime Kuma remains active on
  `3001/tcp`.
- Migrated `oracle` rootless Podman state from the deprecated BoltDB backend to
  SQLite with `podman system migrate --migrate-db`. The old DB was renamed to
  `/home/ubuntu/.local/share/containers/storage/libpod/bolt_state.db-old`.
- Updated the OpenTofu-managed Tailscale policy so
  `group:media-guests`/`nguyenphuongthao9497@gmail.com` can use Tailscale SSH
  to tagged servers on `tag:server:22` and `tag:trusted:22`, with matching ACL
  and SSH policy tests.
- Allowed `group:media-guests`/`nguyenphuongthao9497@gmail.com` to reach
  Jellyfin directly at `100.111.70.79:8096` over Tailscale while keeping Dozzle
  and other non-SSH Jellyfin ports denied by policy tests.
- Added `VM.Config.Memory` to CT 102's `OpenTofuPulseManage` role and increased
  `pulse` from `512M` RAM / `256M` swap to `1024M` RAM / `512M` swap through
  OpenTofu after live memory pressure showed only `23M` available and `42M`
  swap in use.

## 2026-05-04

- Created OpenTofu-managed VM 100 `windows11` from the old Unraid
  `/fast/domains/Windows11/vdisk1.img` qcow2 image. The VM uses OVMF,
  `pc-q35-10.1`, TPM 2.0, SATA boot disk on `fast-vm`, E1000 networking on
  `vmbr0`, and the staged VirtIO driver ISO
  `local:iso/virtio-win-0.1.271-1.iso`. It booted at `192.168.50.227` with RDP
  open, then was set back to stopped with no host boot autostart. Added
  VM/storage/network-scoped OpenTofu ACLs for VMID 100, including VM power
  management, and backed up the updated local state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260504-214447`.
- Updated the OpenTofu-managed `adguard.chienlt.com` Cloudflare record from the
  `cle-viettel` public IP to the `cle-viettel` Tailscale IP `100.107.99.32`.
- Re-added the `adguard.chienlt.com` Traefik router after the DNS record moved
  to the tailnet IP. The router uses `adguard-tailnet-chain` with a Tailscale
  source allowlist, CrowdSec bouncer, and basic security headers, and proxies to
  AdGuard at `http://100.107.99.32:82`. Verified normal tailnet HTTPS returns
  the AdGuard login redirect while a forced public-IP request returns HTTP 403.
- Updated live AdGuard Home persistent clients on `cle-viettel` to match the
  current Tailscale MagicDNS names and `100.x` addresses for 16 devices. The
  runtime config backup is
  `/opt/AdGuardHome/AdGuardHome.yaml.bak-20260504-141034-tailscale-clients`.
- Installed CrowdSec `1.7.7` on `cle-viettel`, configured Traefik access-log
  acquisition from `/root/Source/traefik/logs/access.log`, installed the
  `crowdsecurity/traefik` collection, and created the `traefik-media` bouncer
  key at `/root/Source/traefik/crowdsec/bouncer-key`.
- Enabled Traefik's CrowdSec bouncer plugin for the media routers and added
  `media-public-chain` to Bazarr, Jellyfin, Jellyseerr, and Plex. The chain
  applies CrowdSec blocking, a lenient `600/minute` rate limit with `300` burst,
  and basic security headers. `timthuoc.chienlt.com` is unchanged.
- Verified a manual CrowdSec ban returned HTTP 403 for
  `jellyseerr.chienlt.com`, deleting the decision restored the normal HTTP 307
  login redirect, and `cscli decisions list` was empty at post-check. Live
  backups were written as
  `/root/Source/traefik/docker-compose.yml.bak-20260504-110718`,
  `/root/Source/traefik/rules/rules.yml.bak-20260504-110718`, and
  `/etc/crowdsec/config.yaml.bak-20260504-110702`.
- Added `VM.Config.Memory` to VM 121's `OpenTofuSelfhostManage` role, reduced
  `selfhost-pve` memory from 12G to 8G through OpenTofu, and restarted the VM
  so the lower memory limit takes effect.
- Enabled VM 121 `selfhost-pve` virtio balloon statistics by setting the
  OpenTofu floating memory target to the full 8G allocation.
- Hardened external `cle-viettel` ingress after security review. Disabled the
  public insecure Traefik dashboard/API by setting `--api.insecure=false` and
  removing the `8080/tcp` publish; verified public `8080` times out while
  `80/443` remain reachable.
- Installed persistent `docker-user-firewall.service` on `cle-viettel` to add a
  `DOCKER-USER` guard chain that permits public Docker-published traffic from
  `eth0` only to `80/tcp` and `443/tcp`. Verified public `8000/tcp` times out
  even though the legacy `homiix-app` Docker listener still exists.
- Recreated `homiix-app` on `cle-viettel` with an equivalent Python-based
  Docker healthcheck because the image healthcheck used `curl`, but the image
  does not include `curl`. Verified Docker reports the container healthy and the
  Pulse `homiix-app` health alert cleared.
- Moved literal Traefik Cloudflare DNS and monitoring Watchtower notification
  values into root-only `.env` files on `cle-viettel`. Remote compose backups
  were written as `/root/Source/traefik/docker-compose.yml.bak-20260504-075823`
  and `/root/Source/monitoring/docker-compose.yml.bak-20260504-075823`.
- Narrowed the Tailscale grant from `cle-viettel-vpn` to `jellyfin-pve` from all
  ports to only `8096`, added ACL tests for the allowed and denied ports, and
  applied the OpenTofu-managed policy. Verified `cle-viettel-vpn` can reach
  `jellyfin-pve:8096` but not `jellyfin-pve:7007`.
- Upgraded and rebooted `cle-viettel`. It is now running kernel
  `5.15.0-177-generic`, Tailscale `1.96.4`, and Docker Engine `29.4.2`, with
  no remaining apt upgrades or reboot requirement at post-check.
- Raised Pulse host-agent SMART disk temperature alerting from `60/55 C` to
  `65/60 C` after `cle-pve` disk `sde` reached the previous `60 C` warning
  threshold. Pulse auto-resolved the active disk-temperature alert after the
  config reload. A live backup was written on CT 102 as
  `/etc/pulse/alerts.json.backup-disktemp-20260504-085255`.
- Installed Tailscale `1.96.4` in CT 102 `pulse`, added `/dev/net/tun`
  passthrough for normal LXC tunnel mode, joined it as `pulse-pve` with
  `tag:server`, and imported the new Tailscale tag/key-expiry resources into
  OpenTofu. The tailnet address is `100.86.86.121` and the Proxmox LXC config
  backup is `/root/lxc-102.conf.bak-tailscale-20260504-133008` on `cle-pve`.
- Installed Pulse `v5.1.29` agents on remote tailnet hosts
  `cle-viettel-vpn`, `cle-cloudfly`, and `oracle`, all reporting to CT 102
  through `http://100.86.86.121:7655`. `cle-viettel` also reports Docker
  containers through agent ID `cle-viettel-docker`; `cle-cloudfly` and `oracle`
  are host-only. Added the OpenTofu-managed Tailscale grant allowing only these
  three hosts to reach `pulse-pve:7655`.
- Raised Pulse host-agent SMART disk temperature alerting from `55/50 C` to
  `60/55 C` after `cle-pve` disks hovered around `55-58 C`; existing active
  disk-temperature alerts cleared after the config update. A live backup was
  written on CT 102 as `/etc/pulse/alerts.json.backup-disktemp-20260504-071950`.
- Added Tailscale `group:media-guests` for
  `nguyenphuongthao9497@gmail.com` and granted HTTPS access to VM 121
  `selfhost-pve:443` for Frigate and media services through Traefik. The policy
  tests explicitly deny SSH, direct media backend ports, and NAS/NFS access for
  this group.

## 2026-05-03

- Expanded the live Homepage config on VM 121 with curated `Infrastructure`
  and `Internal Tools` groups, plus N100 home/admin entries for Bambuddy, TRMNL
  BYOS, Matter Server, HA MCP, and Bambuddy's Obico ML status endpoint. Backed
  up the previous live config to
  `/srv/selfhost/homepage/config/services.yaml.bak-admin-dashboard-20260503215324`.
- Added Oracle `Hermes` to the live Homepage `Internal Tools` group, pointing
  at the Hermes WebUI on tailnet port `8787` and monitoring it through
  Homepage's site monitor. Backed up the previous live config to
  `/srv/selfhost/homepage/config/services.yaml.bak-hermes-20260503222018`.
- Removed the stale `Unraid` card from live Homepage and replaced missing icon
  references for hledger, Decluttarr, Reclaimerr, Prefect, and Playwright MCP
  with resolvable Homepage icon sources. Backed up the previous live config to
  `/srv/selfhost/homepage/config/services.yaml.bak-icons-unraid-20260503222935`.
- Decommissioned Maintainerr from VM 121 by removing its Homepage card,
  removing the `maintainerr` service from `/srv/selfhost/docker-compose.yml`,
  and removing the stopped/running container. The persisted data directory
  `/srv/selfhost/maintainerr/data` was left in place for rollback. Backups were
  created at
  `/srv/selfhost/homepage/config/services.yaml.bak-maintainerr-decom-20260503223504`
  and `/srv/selfhost/docker-compose.yml.bak-maintainerr-decom-20260503223512`.
- Updated Reclaimerr's live service config on VM 121 so Jellyfin points to LXC
  `jellyfin-pve` at `http://192.168.50.243:8096` and Plex points to LXC
  `plex-pve` at `http://192.168.50.242:32400`. Radarr, Sonarr, and Seerr remain
  Docker-network local to VM 121. Backed up the SQLite database to
  `/srv/selfhost/reclaimerr/data/database/reclaimerr.db.bak-lxc-endpoints-20260503224421`.
- Added a rootless Pulse Podman agent on N100/current host under user `cle`.
  The user service is `~/.config/systemd/user/pulse-agent.service`, the token
  is stored at `~/.config/pulse-agent/token`, and the agent uses only
  `/run/user/1000/podman/podman.sock` with agent ID `n100-podman`. The Pulse API
  token metadata backup on CT 102 is
  `/etc/pulse/api_tokens.json.backup-n100-podman-agent-20260503-003823`.
- Enabled host collection on the N100 Pulse user service so Pulse shows
  hostname `n100` in Hosts while keeping Podman collection under
  `n100-podman`.
- Added the Pulse `Telegram Alerts` notification webhook from local
  `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` values, verified a Telegram HTTP
  200 test delivery, and activated Pulse alert notifications. The webhook is
  stored encrypted on CT 102 at `/etc/pulse/webhooks.enc`.

## 2026-05-02

- Backed up local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-101715` on
  `cle-pve` with a matching SHA256 file.
- Split CT 102 `pulse` into its own OpenTofu resource as the first low-risk
  tightening candidate.
- Granted `opentofu@pve` a CT-scoped `OpenTofuPulseManage` role on `/vms/102`
  with `VM.Audit,VM.Config.Options`, applied the provider normalization for
  `pulse`, and verified a no-op follow-up plan without blanket
  `ignore_changes = all`.
- Tightened OpenTofu ownership for all remaining LXCs:
  - `110 plex-pve`
  - `111 jellyfin-pve`
  - `112 nas-pve`
  - `113 frigate-pve`
  - `114 immich-pve`
  - `115 backup-pve`
- Each tightened LXC received a CT-scoped `VM.Audit,VM.Config.Options` role for
  provider normalization. Follow-up OpenTofu plan verified no changes.
- Split VM 101 `homelab-pve` into its own tightened OpenTofu resource and
  verified a no-op plan without blanket `ignore_changes = all`.
- Granted `opentofu@pve` a VM-scoped `OpenTofuHomelabManage` role on
  `/vms/101` with `VM.Audit`, `VM.Config.Disk`, `VM.Config.Options`, and
  `VM.GuestAgent.Audit`. `VM.PowerMgmt` was intentionally not granted.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-102758` with
  a matching SHA256 file.
- Split VM 121 `selfhost-pve` into its own tightened OpenTofu resource and
  applied only the state address move, with `0 added, 0 changed, 0 destroyed`.
- Granted `opentofu@pve` a VM-scoped `OpenTofuSelfhostManage` role on
  `/vms/121` with `VM.Audit`, `VM.Config.Disk`, `VM.Config.Options`, and
  `VM.GuestAgent.Audit`. `VM.PowerMgmt` was intentionally not granted.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-115927` with
  a matching SHA256 file.
- Added VM 121 Traefik route for `pulse.chienlt.com` to CT 102 `pulse` at
  `192.168.50.18:7655`.
- Replaced Pulse local password/API-token auth on CT 102 with VM 121
  Traefik-injected proxy auth for `pulse.chienlt.com`, after backing up the
  active `/etc/pulse/.env` and `/etc/pulse/api_tokens.json` files.
- Installed `pulse-agent.service` on `cle-pve`, pointed it at CT 102 Pulse over
  `http://192.168.50.18:7655`, enabled PVE Proxmox mode, and disabled
  Docker/Kubernetes collection for the Proxmox host. The final Pulse agent API
  token is limited to `host-agent:report` and `host-agent:config:read`.
- Migrated Pulse's Proxmox connection from `root@pam` password auth to
  dedicated token auth with `pulse-monitor@pam!pulse-cle-pve-192-168-50-18`.
  Verified Pulse sees one online `cle-pve` host agent with temperature and
  SMART data.
- Added `OpenTofuIdentityManage` on `/access` for `opentofu@pve` with
  `User.Modify` so the provider can refresh imported Proxmox user-token
  metadata without granting `Permissions.Modify`.
- Added OpenTofu resources and imports for the Pulse monitoring identity:
  `PulseMonitor`, `pulse-monitor@pam`, and
  `pulse-monitor@pam!pulse-cle-pve-192-168-50-18`. A follow-up plan verified no
  changes.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-200900` with
  a matching SHA256 file.
- Added containerized Pulse Docker agents to Docker-running LXCs `plex-pve`,
  `jellyfin-pve`, `frigate-pve`, and `immich-pve`. Each agent runs from
  `/opt/pulse-agent/docker-compose.yml`, uses a separate root-only token, mounts
  the local Docker socket, and reports Docker metrics to CT 102 Pulse.
- Added a containerized Pulse Docker agent to VM 121 `selfhost-pve` as service
  `pulse-agent` in `/srv/selfhost/docker-compose.yml`. Its token is stored
  root-only at `/srv/selfhost/pulse-agent/token`, and the live compose backup is
  `/srv/selfhost/docker-compose.yml.bak-pulse-agent-20260502-220226`. The Pulse
  token metadata backup is
  `/etc/pulse/api_tokens.json.backup-selfhost-agent-20260502-220050`.
- Added Dozzle agents to Docker-running LXCs `plex-pve`, `jellyfin-pve`,
  `frigate-pve`, and `immich-pve` from `/opt/dozzle-agent/docker-compose.yml`.
  VM 121 central Dozzle now uses `DOZZLE_REMOTE_AGENT` to read those remote
  Docker logs and was pulled to Dozzle `v10.5.1` after backing up the live
  compose file to
  `/srv/selfhost/docker-compose.yml.bak-dozzle-agents-20260502-214322`.
- Updated external `cle-viettel` Traefik `bazarr.chienlt.com` backend from old
  `unraid-cle` tail IP to VM 121 `selfhost-pve` tail IP
  `100.81.144.82:6767`.
- Updated the Tailscale policy through the API so `cle-viettel-vpn` can reach
  VM 121 Bazarr on port `6767`.
- Imported the live Tailscale tailnet policy into OpenTofu as
  `tailscale_acl.policy`, sourced from
  `proxmox/opentofu/tailscale-policy.hujson`.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-130629` with
  a matching SHA256 file.
- Removed stale `unraid-cle` host mapping and its monitoring, guest, and media
  grants from the OpenTofu-managed Tailscale policy.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-145517` with
  a matching SHA256 file.
- Imported Tailscale DNS config plus stable device tags/key-expiry settings for
  `cle_viettel`, `homelab_pve`, `jellyfin_pve`, `n100`, `oracle`, and
  `selfhost_pve` into OpenTofu with 13 imports and no live changes.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-165000` with
  a matching SHA256 file.
- Added storage-scoped `OpenTofuStorageManage` on `local`, `local-zfs`,
  `fast-vm`, and `tank-backup` because the provider requires
  `Datastore.Allocate` to read/import storage resources.
- Imported Proxmox backup job `nightly-guests`, Proxmox storage definitions,
  Proxmox APT repository enablement, and selected Tailscale route enablement
  into OpenTofu with 16 imports and no live changes.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-173553` with
  a matching SHA256 file.
- Added Cloudflare and Tailscale provider tokens to ignored
  `proxmox/opentofu/.env.local` for local OpenTofu runs.
- Imported current `chienlt.com` Cloudflare DNS records into OpenTofu with 9
  imports and no live DNS changes.
- Backed up the updated local OpenTofu state to
  `/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-181407` with
  a matching SHA256 file.

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
