# Agent Guide

This repository is public. Treat every tracked file and every commit as
internet-visible.

Never commit credentials, runtime state, backup artifacts, app databases, logs,
`.env` files, `.tfstate`, `.tfvars`, private keys, `acme.json`, copied
Claude/Codex state, or generated service data.

## Read First

- `CLAUDE.md`: rootless Podman/Quadlet knowledge for the home automation stack.
- `proxmox/AGENTS.md`: Proxmox, OpenTofu, Tailscale, Cloudflare, and backup
  workflow guidance.
- `proxmox/README.md`: Proxmox documentation map.
- `proxmox/CURRENT_STATE.md`: live infrastructure source of truth.

## Topology Snapshot

This repo covers two related selfhost layers:

- `cle-pve` Proxmox host at `192.168.50.13`, with infrastructure state in
  `proxmox/`.
- The current N100/root stack in this repo root, managed as rootless Podman
  Quadlets under `systemctl --user`.

High-level flow:

```text
Cloudflare / Tailscale DNS
  -> CT116 traefik-pve 192.168.50.247 / 100.112.33.84
       -> Proxmox/LXC services directly
       -> VM121 selfhost-pve Docker apps via 192.168.50.121:13000-13019

cle-pve 192.168.50.13
  VMs:
    100 windows11 stopped
    101 homelab-pve
    121 selfhost-pve, Docker app host, 192.168.50.121 / 100.81.144.82
    122 bazzite-gaming, RTX 3060 passthrough

  LXCs:
    102 pulse monitoring
    110 plex-pve
    111 jellyfin-pve
    112 nas-pve NFS/Samba exports
    113 frigate-pve
    114 immich-pve
    115 backup-pve Kopia
    116 traefik-pve ingress

N100/root Quadlets:
  homeassistant, mqtt, mqtt-explorer, zigbee2mqtt, matter-server,
  ha-mcp, bambuddy, obico-ml-api, trmnl-byos + postgres
```

Important edges:

- `nas-pve` exports `/tank/media` and `/fast/zk`; VM 121 mounts both.
- Intel iGPU is passed to Plex, Jellyfin, Frigate, and Immich LXCs.
- CT 116 Traefik is the main internal/tailnet ingress for `*.chienlt.com`;
  VM 121's old Traefik is stopped and kept only for rollback.
- VM 121 runs the mutable Docker app stack from `/srv/selfhost`.
- Backups are split between Proxmox `nightly-guests` for guest root disks and
  config, and Kopia on CT 115 for Immich photos/dumps plus shared `zk`.
- Runtime app data, service env files, Traefik `acme.json`, databases, and
  generated state stay out of git.

VM 121 `selfhost-pve` Docker services run from mutable state in `/srv/selfhost`;
verify live state with `ssh selfhost-pve 'cd /srv/selfhost && docker compose ps'`
before changing routes or docs.

Current routed VM 121 services:

| Service | LAN-bound backend |
|---|---|
| `homepage` | `192.168.50.121:13000` |
| `dozzle` | `192.168.50.121:13001` |
| `sonarr` | `192.168.50.121:13002` |
| `radarr` | `192.168.50.121:13003` |
| `prowlarr` | `192.168.50.121:13004` |
| `sabnzbd` | `192.168.50.121:13005` |
| `qbittorrent` | `192.168.50.121:13006` |
| `tautulli` | `192.168.50.121:13007` |
| `reclaimerr` | `192.168.50.121:13008` |
| `dockge` | `192.168.50.121:13009` |
| `filebrowser` | `192.168.50.121:13010` |
| `silverbullet` | `192.168.50.121:13011` |
| `speedtest-tracker` | `192.168.50.121:13012` |
| `dockhand` | `192.168.50.121:13013` |
| `hledger-webapp` | `192.168.50.121:13014` |
| `openspeedtest` | `192.168.50.121:13015` |
| `bazarr` | `192.168.50.121:13016` |
| `syncthing` | `192.168.50.121:13017` |
| `seerr` | `192.168.50.121:13018` |
| `watchstate` | `192.168.50.121:13019` |

Other running VM 121 Compose services:

```text
decluttarr
dockerproxy
flaresolverr
playwright-mcp
pulse-agent
recyclarr
tailscale-mcp
watchtower
```

## Worktree Safety

- The worktree may already contain user edits. Check `git status --short` and
  inspect diffs before editing.
- Do not revert or overwrite changes you did not make.
- Prefer `rg` for search.
- Use `apply_patch` for manual file edits.
- Do not run destructive commands such as `git reset --hard`, `git checkout --`
  on user files, dataset destroy, or guest destroy unless explicitly requested.

## Public Repo Checks

Before pushing, scan the exact tracked tree:

```bash
git status --short
git ls-files | rg -n '(^|/)(\.env|\.env\..*|.*\.env|.*\.pem|.*\.key|.*\.tfstate|.*\.tfvars|id_rsa|id_ed25519|acme\.json|.*sqlite.*|.*\.db)$' || true

tmp="$(mktemp -d)"
git ls-files -z | rsync -a --from0 --files-from=- ./ "$tmp"/
nix run nixpkgs#gitleaks -- dir "$tmp" --redact --verbose --no-banner
rm -rf "$tmp"
```

For a full history scan, archive each commit to a temp directory and run
`gitleaks dir` on the archive output. `gitleaks git` has reported `0 commits
scanned` in this repo, so do not trust that mode without checking its output.

## Root Stack

Root-level config tracks selected rootless Podman Quadlets. Runtime directories
and env files are ignored.

The live stack runs under `systemctl --user`, not plain `podman restart`:

```bash
systemctl --user daemon-reload
systemctl --user restart <name>
journalctl --user -u <name> -f
```

Important facts:

- `docker-compose.yml` is legacy for the root stack.
- Tracked Quadlet sources live under `quadlet/`.
- Home Assistant and matter-server rely on the custom D-Bus UID proxy described
  in `CLAUDE.md`.
- `podman restart <name>` can break Quadlet-managed services; use systemd.
- Bambuddy runs on host networking at port `8000`; Obico ML API runs on
  `127.0.0.1:3333`.

For docs-only changes outside OpenTofu, `git diff --check` is the minimum
verification. When pushing public changes, also run the tracked-tree secret
scan above.
