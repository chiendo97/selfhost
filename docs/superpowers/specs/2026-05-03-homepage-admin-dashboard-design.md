# Homepage Admin Dashboard Expansion Design

Date: 2026-05-03

## Context

Homepage runs on VM 121 `selfhost-pve` with live mutable config under
`/srv/selfhost/homepage/config`. The current dashboard mostly covers VM 121
Docker services and a few Proxmox LXC-backed services. The broader live
inventory also includes Proxmox LXCs, N100 rootless Podman services, and Oracle
host services.

The live Homepage files contain API keys and credentials. This design documents
service taxonomy and behavior only; secrets stay in runtime config and are not
copied into the repository.

## Goal

Expand Homepage so it is useful as a daily admin dashboard for user-facing,
internal, and infrastructure endpoints across:

- VM 121 `selfhost-pve`
- Proxmox LXCs on `cle-pve`
- N100 rootless Podman services
- Oracle host services

## Scope

Add curated service entries rather than dumping every process or dependency.
Include services with a UI, an admin workflow, a health endpoint, or meaningful
Homepage/Proxmox/Docker metadata. Exclude pure backing dependencies such as
Postgres and Redis unless they have a human-facing UI or useful health endpoint.

## Dashboard Structure

Keep the existing groups where they already fit daily use:

- `Media`
- `Media Managerment`
- `File Managerment`
- `Network Managerment`
- `Monitor Managerment`
- `Home Managerment`

Add or expand these areas:

- `Infrastructure`: Proxmox, Pulse, Kopia, Dozzle, Traefik, router links.
- `Internal Tools`: Prefect, Silverbullet, Playwright MCP, Tailscale MCP, HA
  MCP, Obico ML health, Matter Server, TRMNL BYOS.
- `Home Managerment`: Bambuddy, TRMNL BYOS, Matter Server, HA MCP, alongside
  Home Assistant, Zigbee2MQTT, and MQTT Explorer.

## Integrations

Use existing Homepage patterns:

- `server` and `container` for VM 121 Docker services already reachable through
  the configured Docker socket proxy.
- `siteMonitor` for internal/admin HTTP endpoints where a simple HEAD/GET check
  is meaningful.
- Native widgets only where the service supports one and credentials already
  exist in live config or can be safely sourced from runtime state.
- Proxmox metadata via `proxmoxNode`, `proxmoxVMID`, and `proxmoxType` for
  Proxmox VMs/LXCs if the live `proxmox.yaml` has a usable read-only token.

## Safety

Before editing, back up the live Homepage config file being changed. Do not
print or commit API keys, passwords, token secrets, `.env` files, databases, or
runtime state. Runtime config remains on VM 121; the repository receives only
documentation if needed.

## Verification

After editing:

- Parse the changed YAML.
- Restart or let the Homepage container reload as appropriate.
- Check Homepage container logs for config errors.
- Verify the dashboard URL responds.
- Spot-check added internal links from VM 121 where practical.
