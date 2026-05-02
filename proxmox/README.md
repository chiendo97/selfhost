# cle-pve Infrastructure Docs

This directory is the current source of truth for the `cle-pve` Proxmox setup.
It describes the live infrastructure after the Unraid migration and should be
updated whenever guests, storage, routes, or backup policy changes.

## Documents

| File | Purpose |
|---|---|
| `CURRENT_STATE.md` | Live inventory: hosts, guests, IPs, storage, mounts, routes, and service ownership. |
| `BACKUPS.md` | Current backup jobs, backup storage, restore pattern, and what is not backed up. |
| `OPERATIONS.md` | Common commands and runbooks for day-to-day maintenance. |
| `CHANGELOG.md` | Dated infrastructure changes and migration milestones. |
| `CLAUDE.md` | Short agent-facing context for future automation sessions. |
| `opentofu/` | First IaC layer for adopting existing Proxmox guests into OpenTofu state. |

## Rules

- Keep this directory current-state focused. Put historical detail in
  `CHANGELOG.md`, not in active runbooks.
- Do not commit copied runtime state such as `.claude`, credentials, logs,
  Caddyfiles, Docker `.env` files, or app databases.
- The repo `.gitignore` only unignores root-level `proxmox/*.md` files and the
  `proxmox/opentofu` IaC scaffold on purpose.
- Prefer live verification from `cle-pve` before updating facts here.

## Main Access

```bash
ssh cle-pve
```

Proxmox UI:

```text
https://192.168.50.13:8006
```
