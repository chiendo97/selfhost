# Proxmox Agent Guide

This directory is the current-state source of truth for the `cle-pve` Proxmox
setup. Keep `CURRENT_STATE.md` current for live topology/config changes and add
dated entries to `CHANGELOG.md`. Keep historical detail out of active runbooks
unless it changes how future work should be done.

## Read First

- `README.md`: doc map and documentation rules.
- `CURRENT_STATE.md`: current live inventory and source of truth.
- `BACKUPS.md`: backup coverage and restore flow.
- `OPERATIONS.md`: common commands and maintenance runbooks.
- `opentofu/README.md`: OpenTofu ownership, credentials, state, and adoption
  notes.

## Proxmox Access

Main host:

```bash
ssh cle-pve
```

Useful checks:

```bash
ssh cle-pve 'qm list; pct list'
ssh cle-pve 'pvesm status; zpool status; zfs list'
ssh cle-pve 'pct config 114'
ssh cle-pve 'qm config 121'
```

Current critical facts:

- Proxmox host: `cle-pve`, LAN `192.168.50.13`.
- VM 121: `selfhost-pve`, LAN `192.168.50.121`, tail `100.81.144.82`.
- VM 121 still needs `/mnt/user/media` from `nas-pve`; do not decommission
  `nas-pve` unless that workflow is replaced.
- `fast/selfhost` is decommissioned; rollback copy is
  `fast/selfhost-decom-20260501`.
- Immich live data is `/fast/immich-app`.
- Frigate recordings are `/tank/frigate/storage`.
- Proxmox guest backups are managed by job `nightly-guests`.
- Kopia in CT 115 backs up Immich photos from `/source/immich-app/photos`.
- Pulse monitoring uses CT 102 plus a `cle-pve` host agent; token secrets are
  root-only on the host and must not be committed.

## OpenTofu

Run OpenTofu from `proxmox/opentofu`:

```bash
cd proxmox/opentofu
set -a
. ./.env.local
set +a
nix run nixpkgs#opentofu -- init
nix run nixpkgs#opentofu -- fmt -recursive -check
nix run nixpkgs#opentofu -- validate
nix run nixpkgs#opentofu -- plan -detailed-exitcode
```

Ignored `.env.local` contains local provider credentials:

- `PROXMOX_VE_API_TOKEN`
- `TAILSCALE_API_KEY`
- `CLOUDFLARE_API_TOKEN`
- `CF_DNS_API_TOKEN`

Never print token values. The expected plan should normally be no-op. The
Tailscale DNS resource currently emits an alpha warning; that warning alone is
expected.

OpenTofu currently owns:

- all active Proxmox guests and selected resource settings;
- Tailscale policy, DNS, stable device tags/key-expiry, and selected route
  enablement;
- Proxmox backup job, storage definitions, APT repository enablement, and
  Pulse monitoring identity metadata;
- current `chienlt.com` Cloudflare DNS records.

OpenTofu does not yet own:

- ZFS pools/datasets and host system packages/services;
- zram/sysctl;
- Tailscale device lifecycle/auth/authorization;
- NixOS, Home Manager, Docker, Traefik, Homepage, or app config.

Those remain manual/docs-managed until an Ansible or Nix layer is added.

## OpenTofu Imports

`opentofu/imports.tf` is for adopting existing live resources into state. It
maps a provider resource ID to a configured OpenTofu address:

```hcl
import {
  to = cloudflare_dns_record.chienlt["plex"]
  id = "zone_id/record_id"
}
```

After a resource is imported, the import block is optional documentation. If
you remove a resource from config, remove the matching import block too.

Two common intents:

- Delete the real resource: remove it from the `.tf` config, remove its import
  block, run `tofu plan`, confirm the destroy, then apply.
- Stop managing but keep it live: run `tofu state rm '<resource address>'`,
  then remove it from config and remove its import block. The next plan should
  be no-op for that resource.

For Cloudflare records pointing to Tailscale `100.x` addresses, keep
`proxied = false`; Cloudflare's proxy cannot reach private tailnet addresses.

## Backups And State

Before risky OpenTofu adoption or state moves, back up local state to
`cle-pve:/tank/fast-backups/opentofu/cle-pve/` and write a matching SHA256
file. See `opentofu/README.md` for the current backup path.

Before deleting a guest or dataset:

1. Confirm no PVE config references it.
2. Confirm no process has files open with `fuser -vm <path>`.
3. Confirm backup/rollback exists or intentionally does not matter.
4. Stop first and observe impact before destroying.
5. Prefer a read-only rollback rename before final destroy.

## Verification

For OpenTofu/doc changes, run at minimum:

```bash
git diff --check
cd proxmox/opentofu
set -a; . ./.env.local; set +a
nix run nixpkgs#opentofu -- fmt -recursive -check
nix run nixpkgs#opentofu -- validate
nix run nixpkgs#opentofu -- plan -detailed-exitcode
```

For Proxmox docs-only changes, `git diff --check` is the minimum. When pushing
public changes, also run a tracked-tree secret scan from the repo root.
