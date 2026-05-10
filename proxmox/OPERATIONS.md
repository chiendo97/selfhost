# cle-pve Operations

Common commands for day-to-day management.

## Proxmox Host

```bash
ssh cle-pve
pveversion
pvesm status
zpool status
zfs list
```

Guest inventory:

```bash
ssh cle-pve 'qm list; pct list'
```

Guest configs:

```bash
ssh cle-pve 'qm config 121'
ssh cle-pve 'pct config 114'
```

Enter or run commands in LXCs:

```bash
ssh cle-pve 'pct enter 114'
ssh cle-pve 'pct exec 114 -- docker ps'
```

Run a command in VM 121 through QEMU guest agent:

```bash
ssh cle-pve 'qm guest exec 121 -- /run/current-system/sw/bin/hostname'
```

## VM 121 Selfhost

Preferred access:

```bash
ssh cle@100.81.144.82
cd /srv/selfhost
```

Docker lifecycle:

```bash
docker compose ps
docker compose up -d <service>
docker compose logs -f <service>
docker compose pull <service>
docker compose up -d <service>
```

There is intentionally no `selfhost-compose.service`. Containers rely on Docker
restart policies after boot. Run Compose manually when definitions change.

VM 121 publishes Docker-backed Traefik backends directly on LAN-bound high
ports:

```bash
ssh selfhost-pve 'ss -ltn | awk '\''NR==1 || /192\\.168\\.50\\.121:13/'\'''
ssh cle-pve 'pct exec 116 -- curl -fsS -I --max-time 8 http://192.168.50.121:13000'
```

The old VM 121 Traefik service is behind the `old-traefik` profile. Start it
only for rollback:

```bash
ssh selfhost-pve 'cd /srv/selfhost && docker compose --profile old-traefik up -d traefik'
```

## VM 122 Bazzite Gaming

VM 122 is a Bazzite gaming VM with RTX 3060 passthrough attached.
VM Secure Boot is disabled via `efidisk0` `pre-enrolled-keys=0`.

Current config checks:

```bash
ssh cle-pve 'qm config 122'
ssh cle-pve 'qm status 122'
ssh -i ~/.ssh/id_ed25519_selfhost cle@192.168.50.8 'hostname; nvidia-smi'
```

RTX 3060 passthrough checks:

```bash
ssh cle-pve 'lspci -nnk -s 01:00.0; lspci -nnk -s 01:00.1'
ssh cle-pve 'qm config 122 | grep -E "^(hostpci[0-9]|vga|boot|efidisk0|scsi0|memory):"'
```

Expected GPU/audio state:

```text
vga: none
01:00.0 GPU   10de:2504  Kernel driver in use: vfio-pci
01:00.1 audio 10de:228e  Kernel driver in use: vfio-pci
IOMMU group 15 contains only 01:00.0 and 01:00.1
```

Sunshine checks:

```bash
ssh -i ~/.ssh/id_ed25519_selfhost cle@192.168.50.8 'ujust setup-sunshine status'
ssh -i ~/.ssh/id_ed25519_selfhost cle@192.168.50.8 'systemctl --user status homebrew.sunshine.service --no-pager'
ssh -i ~/.ssh/id_ed25519_selfhost cle@192.168.50.8 'journalctl --user -u homebrew.sunshine.service -b --no-pager | grep -E "Found monitor|Found H\\.264|Found HEVC|Permission denied|Fatal"'
curl -k -L --max-time 8 -sS -o /dev/null -w '%{http_code} %{url_effective}\n' https://192.168.50.8:47990
```

Expected Sunshine state:

```text
`ujust setup-sunshine status` returns `enable`.
`homebrew.sunshine.service` is active in the `cle` graphical session.
The RTX 3060 has an HDMI dummy plug connected as `HDMI-A-1`.
Sunshine logs show H.264 and HEVC encoders through NVENC.
The web UI redirects to `https://192.168.50.8:47990/welcome` for first setup.
```

## Traefik LXC

```bash
ssh cle-pve 'pct exec 116 -- sh -lc "cd /srv/traefik && docker compose ps"'
ssh cle-pve 'pct exec 116 -- sh -lc "cd /srv/traefik && docker compose logs -f traefik"'
ssh cle-pve 'pct exec 116 -- sh -lc "tailscale status; tailscale ip -4"'
```

Dry-run a route before DNS changes:

```bash
ssh cle-pve 'pct exec 116 -- curl -k --resolve frigate.chienlt.com:443:192.168.50.247 https://frigate.chienlt.com/api/version'
```

## NixOS Rebuilds

Dotfiles source:

```bash
cd /home/cle/Source/dotfiles/home-manager/.config/home-manager
```

Build/check:

```bash
nix flake check
```

Rebuild VM 121 from inside VM 121:

```bash
sudo nixos-rebuild switch --flake /home/cle/Source/dotfiles/home-manager/.config/home-manager#selfhost-pve
home-manager switch --flake /home/cle/Source/dotfiles/home-manager/.config/home-manager#selfhost-pve
```

If SSH to VM 121 is unavailable, run through the guest agent as user `cle`:

```bash
ssh cle-pve 'qm guest exec 121 --timeout 0 -- /bin/sh -lc "runuser -u cle -- sudo -n /run/current-system/sw/bin/nixos-rebuild switch --flake /home/cle/Source/dotfiles/home-manager/.config/home-manager#selfhost-pve"'
```

## Service Checks

HTTP checks from `cle-pve`:

```bash
ssh cle-pve 'curl -fsS -I --max-time 8 http://192.168.50.242:32400/web/index.html'
ssh cle-pve 'curl -fsS -I --max-time 8 http://192.168.50.243:8096'
ssh cle-pve 'curl -fsS -I --max-time 8 http://192.168.50.245:5000'
ssh cle-pve 'curl -fsS -I --max-time 8 http://192.168.50.246:2283'
```

Docker checks:

```bash
ssh cle-pve 'pct exec 110 -- docker ps'
ssh cle-pve 'pct exec 111 -- docker ps'
ssh cle-pve 'pct exec 113 -- docker ps'
ssh cle-pve 'pct exec 114 -- docker ps'
```

Pulse Docker agent checks:

```bash
ssh cle-pve 'for id in 110 111 113 114; do pct exec "$id" -- docker ps --filter name=pulse-agent; done'
ssh cle-pve 'for id in 110 111 113 114; do pct exec "$id" -- sh -lc "cd /opt/pulse-agent && docker compose ps"; done'
ssh selfhost-pve 'cd /srv/selfhost && docker compose ps pulse-agent'
ssh selfhost-pve 'docker logs --tail 80 pulse-agent'
ssh cle-pve 'pct exec 102 -- journalctl -u pulse --since "10 minutes ago" --no-pager | grep -E "dockerContainer|pulse-agent|Docker container health"'
```

N100 rootless Podman Pulse agent checks, run on N100 as user `cle`:

```bash
systemctl --user status pulse-agent.service --no-pager
journalctl --user -u pulse-agent.service --since "10 minutes ago" --no-pager
podman ps -a
```

Pulse notification checks:

```bash
curl -fsS -H 'Accept: application/json' -H 'X-Requested-With: XMLHttpRequest' https://pulse.chienlt.com/api/notifications/health | jq .
curl -fsS -H 'Accept: application/json' -H 'X-Requested-With: XMLHttpRequest' https://pulse.chienlt.com/api/alerts/config | jq '{enabled, activationState, diskTemperature:.hostDefaults.diskTemperature}'
ssh cle-pve 'pct exec 102 -- stat -c "%a %U:%G %n" /etc/pulse/webhooks.enc'
```

Pulse LXC Tailscale checks:

```bash
ssh cle-pve 'pct exec 102 -- sh -lc '\''tailscale status --json | jq "{host:.Self.HostName,dns:.Self.DNSName,ips:.Self.TailscaleIPs,tags:.Self.Tags,online:.Self.Online}"'\'''
ssh cle-pve 'pct exec 102 -- sh -lc "ls -l /dev/net/tun; systemctl is-active tailscaled pulse"'
curl -fsS -I --max-time 8 http://100.86.86.121:7655/ | sed -n '1,5p'
```

Dozzle remote agent checks:

```bash
ssh cle-pve 'for id in 110 111 113 114; do pct exec "$id" -- docker ps --filter name=dozzle-agent; done'
ssh cle-pve 'for id in 110 111 113 114; do pct exec "$id" -- sh -lc "cd /opt/dozzle-agent && docker compose ps"; done'
ssh selfhost-pve 'for host in 192.168.50.242 192.168.50.243 192.168.50.245 192.168.50.246; do timeout 3 bash -lc "</dev/tcp/$host/7007" && echo "$host open"; done'
ssh selfhost-pve 'docker logs --tail 80 dozzle'
```

## NAS Media Export

Check exports:

```bash
ssh cle-pve 'pct exec 112 -- exportfs -v'
ssh cle-pve 'pct exec 112 -- tailscale status --self'
```

Check VM121 media mount:

```bash
ssh cle-pve 'qm guest exec 121 -- /run/current-system/sw/bin/findmnt -T /mnt/user/media'
```

Write test from VM121:

```bash
ssh cle-pve 'qm guest exec 121 -- /bin/sh -lc "p=/mnt/user/media/.vm121-nfs-write-test; echo test > $p; rm -f $p"'
```

Check Oracle Hermes zk mount:

```bash
ssh oracle 'findmnt /home/hermes/zk'
ssh oracle 'sudo -u hermes sh -lc "p=/home/hermes/zk/.hermes-rw-test; echo test > $p; rm -f $p"'
```

## Backups

Proxmox job config:

```bash
ssh cle-pve 'pvesh get /cluster/backup --output-format yaml'
```

List backup archives:

```bash
ssh cle-pve 'pvesm list tank-backup --content backup'
```

Manual guest backup:

```bash
ssh cle-pve 'vzdump --all --storage tank-backup --mode snapshot --compress zstd --zstd 1 --notes-template "{{guestname}}"'
```

Kopia status:

```bash
ssh cle-pve 'pct exec 115 -- systemctl status kopia-server.service --no-pager'
ssh cle-pve 'pct exec 115 -- bash -lc ". /root/kopia-secrets.env && kopia --config-file=/etc/kopia/repository.config policy list"'
ssh cle-pve 'pct exec 115 -- bash -lc ". /root/kopia-secrets.env && kopia --config-file=/etc/kopia/repository.config snapshot list --all"'
```

## Adding A New VM Or LXC

1. Set a stable hostname and DHCP reservation if needed.
2. Put root disk on `fast-vm` unless there is a specific reason not to.
3. Set `onboot=1` and a startup order.
4. Check whether any bind-mounted host data needs separate backup coverage.
5. Confirm the all-guests Proxmox backup job includes it.
6. Add the guest to `CURRENT_STATE.md`.
7. Add a dated entry to `CHANGELOG.md`.

## Decommissioning

Before deleting a VM, LXC, or dataset:

1. Confirm no PVE config references it.
2. Confirm no process has files open with `fuser -vm <path>`.
3. Confirm backup/rollback exists or intentionally does not matter.
4. Stop first and observe impact before destroying.
5. Prefer renaming datasets read-only for rollback before final destroy.
