# Homepage Admin Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the live Homepage dashboard on `selfhost-pve` with curated infrastructure, internal/admin, N100, Oracle, and Proxmox LXC entries.

**Architecture:** Homepage is configured by YAML files under `/srv/selfhost/homepage/config` on VM 121. The implementation edits only live `services.yaml`, reusing the existing Docker integration and adding simple HTTP monitors for endpoints that do not have native Homepage widgets.

**Tech Stack:** Homepage v1.12.3, YAML, Docker Compose on VM 121, Proxmox LXCs, N100 rootless Podman services.

---

### Task 1: Prepare Live Config Backup

**Files:**
- Read: `/srv/selfhost/homepage/config/services.yaml`
- Create: `/srv/selfhost/homepage/config/services.yaml.bak-admin-dashboard-<timestamp>`

- [ ] **Step 1: Back up the live Homepage services config**

Run:

```bash
ssh selfhost-pve 'ts="$(date +%Y%m%d%H%M%S)"; cp -a /srv/selfhost/homepage/config/services.yaml "/srv/selfhost/homepage/config/services.yaml.bak-admin-dashboard-$ts"; ls -l "/srv/selfhost/homepage/config/services.yaml.bak-admin-dashboard-$ts"'
```

Expected: a new backup file path and size are printed.

- [ ] **Step 2: Parse the current YAML before editing**

Run:

```bash
ssh selfhost-pve 'python3 - <<'"'"'PY'"'"'
import yaml
with open("/srv/selfhost/homepage/config/services.yaml", "r", encoding="utf-8") as f:
    yaml.safe_load(f)
print("services.yaml parses")
PY'
```

Expected: `services.yaml parses`.

### Task 2: Apply Curated Dashboard Entries

**Files:**
- Modify: `/srv/selfhost/homepage/config/services.yaml`

- [ ] **Step 1: Add or update entries in `services.yaml`**

Add curated entries while preserving existing credentials and widgets:

- `Infrastructure`: Proxmox, Pulse, Kopia, Dozzle, Traefik, Dockge, Dockhand, Asus WRT, Viettel Router.
- `Internal Tools`: Prefect, Silverbullet, Playwright MCP, Tailscale MCP, HA MCP, Obico ML API, Matter Server, TRMNL BYOS.
- `Home Managerment`: Bambuddy, TRMNL BYOS, Matter Server, HA MCP.
- Proxmox metadata on LXC-backed services where useful: Plex, Jellyfin, Frigate, Immich, Pulse, Kopia.

Use `siteMonitor` for internal endpoints where a simple HTTP check is meaningful. Use `server: my-docker` and `container: <name>` only for VM 121 Docker containers reachable through the existing Docker socket proxy.

- [ ] **Step 2: Avoid committing or printing secret values**

Do not add live Homepage credentials to repository files. Do not print the updated file contents unless secrets are redacted.

### Task 3: Verify Homepage

**Files:**
- Read: `/srv/selfhost/homepage/config/services.yaml`
- Read: VM 121 Docker logs for `homepage`

- [ ] **Step 1: Parse the changed YAML**

Run:

```bash
ssh selfhost-pve 'python3 - <<'"'"'PY'"'"'
import yaml
with open("/srv/selfhost/homepage/config/services.yaml", "r", encoding="utf-8") as f:
    yaml.safe_load(f)
print("services.yaml parses")
PY'
```

Expected: `services.yaml parses`.

- [ ] **Step 2: Restart Homepage**

Run:

```bash
ssh selfhost-pve 'cd /srv/selfhost && docker compose restart homepage'
```

Expected: Docker Compose restarts the `homepage` container.

- [ ] **Step 3: Check Homepage logs**

Run:

```bash
ssh selfhost-pve 'docker logs --tail 120 homepage'
```

Expected: no YAML parse error or fatal startup error.

- [ ] **Step 4: Check dashboard response**

Run:

```bash
ssh selfhost-pve 'curl -fsS -I --max-time 8 http://127.0.0.1:3000'
```

Expected: HTTP success response from Homepage.

- [ ] **Step 5: Spot-check added endpoints from VM 121**

Run targeted `curl -I` or TCP checks for endpoints added as `siteMonitor`, accepting expected auth redirects for protected UIs.

Expected: reachable endpoints respond with HTTP status or open TCP where the service is not HTTP-friendly.
