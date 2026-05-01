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

## NAS Media Export

Check exports:

```bash
ssh cle-pve 'pct exec 112 -- exportfs -v'
```

Check VM121 media mount:

```bash
ssh cle-pve 'qm guest exec 121 -- /run/current-system/sw/bin/findmnt -T /mnt/user/media'
```

Write test from VM121:

```bash
ssh cle-pve 'qm guest exec 121 -- /bin/sh -lc "p=/mnt/user/media/.vm121-nfs-write-test; echo test > $p; rm -f $p"'
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
ssh cle-pve 'pct exec 115 -- bash -lc ". /root/kopia-secrets.env && kopia snapshot list --all"'
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
