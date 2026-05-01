# Agent Context For cle-pve

Read these first:

1. `README.md`
2. `CURRENT_STATE.md`
3. `BACKUPS.md`
4. `OPERATIONS.md`
5. `CHANGELOG.md`

This directory is current-state infra documentation, not a migration transcript.
Update `CURRENT_STATE.md` for live topology changes and `CHANGELOG.md` for
dated changes.

## Safety

- Do not commit runtime state, credentials, `.claude`, `.codex`, Docker `.env`
  files, logs, app databases, or copied backup artifacts.
- Do not delete guests or datasets without first checking live references,
  open files, and rollback.
- Prefer `rg` for searches.
- Use `ssh cle-pve` for host checks and `pct exec` or `qm guest exec` for guest
  checks.
- VM 121 still needs `/mnt/user/media` from `nas-pve`; do not decommission
  `nas-pve` unless that workflow is replaced.

## Current Critical Facts

- Proxmox host: `cle-pve` at `192.168.50.13`.
- VM 121: `selfhost-pve`, LAN `192.168.50.121`, tail `100.81.144.82`.
- `nas-pve` exports only `/tank/media`.
- `fast/selfhost` is decommissioned; rollback copy is
  `fast/selfhost-decom-20260501`.
- Immich live data remains on `/fast/immich-app`.
- Frigate recordings remain on `/tank/frigate/storage`.
- Proxmox guest backups are managed by job `nightly-guests`.
- Kopia in CT 115 backs up `/source/immich-app/photos`.
