# Traefik LXC Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move public ingress from VM 121 Docker Traefik to a small Proxmox LXC while preserving automatic Docker-label routing for services on VM 121.

**Architecture:** Use a new `traefik-pve` LXC as the edge TLS/DNS entrypoint. Keep the existing VM 121 Traefik as an internal Docker app router so Docker labels continue to work without publishing every Docker container port to the LAN. Move non-Docker static routes to the LXC after the edge proxy is proven.

**Tech Stack:** Proxmox LXC, Debian, Traefik v3, Cloudflare DNS-01, Tailscale, existing VM 121 Docker Traefik, existing file-provider YAML.

---

## Current Constraint

The existing VM 121 Traefik discovers Docker services on the Docker bridge network and can route directly to container IPs. A Traefik process running in a separate LXC cannot reach those Docker bridge IPs.

Therefore, a one-step move of the Docker provider to the LXC would break most auto-discovered Docker apps unless we also publish every app port on VM 121 and configure Traefik with `useBindPortIP=true`.

The safer design is:

```text
Internet / Tailscale / LAN
  -> traefik-pve LXC edge Traefik
    -> explicit LXC/N100/PVE backends directly
    -> wildcard fallback to VM121 internal Traefik for Docker-label apps
      -> Docker containers on VM121 selfhost network
```

This keeps Docker auto-routing working and lets us migrate ingress incrementally.

## Target Guests

```text
116 traefik-pve
  OS: Debian LXC
  RAM: 512M
  Swap: 256M
  Cores: 1
  Disk: 4G-8G
  LAN: 192.168.50.54/24, gateway 192.168.50.1
  Tailnet: enabled, hostname traefik-pve
```

Confirm `192.168.50.54` is free before creating the container.

## Files

Create on `traefik-pve`:

```text
/etc/traefik/traefik.yml
/etc/traefik/rules/edge.yml
/etc/traefik/traefik.env
/var/lib/traefik/acme.json
/etc/systemd/system/traefik.service
```

Keep on VM 121:

```text
/srv/selfhost/docker-compose.yml
/srv/selfhost/traefik2/rules/proxmox.yml
/srv/selfhost/traefik2/acme/acme.json
```

VM 121 Traefik remains running during Phase 1 and Phase 2. It becomes the internal Docker router instead of the public edge.

---

## Task 1: Create `traefik-pve` LXC

- [ ] **Step 1: Verify candidate IP is free**

Run:

```bash
ssh cle-pve 'ping -c 2 -W 1 192.168.50.54 || true'
```

Expected: no replies.

- [ ] **Step 2: Create the LXC**

Use the existing Debian template style used by other LXCs. Target config:

```text
vmid: 116
hostname: traefik-pve
cores: 1
memory: 512
swap: 256
rootfs: fast-vm, 8G
net0: vmbr0, static 192.168.50.54/24, gw 192.168.50.1
start at boot: yes
boot order: before VM121 or before public app consumers
```

- [ ] **Step 3: Install base packages**

Run inside the LXC:

```bash
apt update
apt install -y curl ca-certificates tar systemd openssh-server
```

Expected: SSH and systemd available.

---

## Task 2: Install Traefik In LXC

- [ ] **Step 1: Install Traefik binary**

Use the same major version as current VM 121 Traefik, v3.

```bash
curl -fsSL -o /tmp/traefik.tar.gz \
  https://github.com/traefik/traefik/releases/download/v3.6.15/traefik_v3.6.15_linux_amd64.tar.gz
tar -xzf /tmp/traefik.tar.gz -C /tmp traefik
install -m 0755 /tmp/traefik /usr/local/bin/traefik
traefik version
```

Expected: Traefik v3.6.15 prints successfully.

- [ ] **Step 2: Create config directories**

```bash
install -d -m 0755 /etc/traefik/rules
install -d -m 0700 /var/lib/traefik
touch /var/lib/traefik/acme.json
chmod 0600 /var/lib/traefik/acme.json
```

---

## Task 3: Configure Edge Traefik

- [ ] **Step 1: Create `/etc/traefik/traefik.yml`**

```yaml
global:
  checkNewVersion: true
  sendAnonymousUsage: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: dns-cloudflare
        domains:
          - main: chienlt.com
            sans:
              - "*.chienlt.com"

api:
  dashboard: true

log:
  level: INFO

accessLog: {}

serversTransport:
  insecureSkipVerify: true

providers:
  file:
    directory: /etc/traefik/rules
    watch: true

certificatesResolvers:
  dns-cloudflare:
    acme:
      storage: /var/lib/traefik/acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
        delayBeforeCheck: 90
```

- [ ] **Step 2: Create `/etc/traefik/traefik.env`**

Copy the Cloudflare token from the local ignored `.env` or VM 121 Traefik environment without printing it:

```text
CF_DNS_API_TOKEN=<redacted>
```

Set permissions:

```bash
chmod 0600 /etc/traefik/traefik.env
```

---

## Task 4: Configure Dynamic Routes

- [ ] **Step 1: Create `/etc/traefik/rules/edge.yml`**

Start with explicit infra/N100/LXC routes plus a low-priority wildcard fallback to VM 121 internal Traefik:

```yaml
http:
  routers:
    proxmox-rtr:
      rule: "Host(`proxmox.chienlt.com`)"
      entryPoints: [websecure]
      service: proxmox-svc
      priority: 100
      tls:
        certResolver: dns-cloudflare

    bambuddy-rtr:
      rule: "Host(`bambuddy.chienlt.com`)"
      entryPoints: [websecure]
      service: bambuddy-svc
      priority: 100
      tls:
        certResolver: dns-cloudflare

    docker-vm121-fallback-rtr:
      rule: "HostRegexp(`{subdomain:[a-z0-9-]+}.chienlt.com`)"
      entryPoints: [websecure]
      service: vm121-traefik-svc
      priority: 1
      tls:
        certResolver: dns-cloudflare

  services:
    proxmox-svc:
      loadBalancer:
        servers:
          - url: "https://192.168.50.13:8006"

    bambuddy-svc:
      loadBalancer:
        servers:
          - url: "http://100.107.253.59:8000"

    vm121-traefik-svc:
      loadBalancer:
        passHostHeader: true
        servers:
          - url: "https://192.168.50.121"
```

- [ ] **Step 2: Add more explicit routes after edge is proven**

Move these from VM 121 file provider to the LXC one-by-one:

```text
ha.chienlt.com              -> http://100.107.253.59:8123
z2m.chienlt.com             -> http://100.107.253.59:8080
mqtt-explorer.chienlt.com   -> http://100.107.253.59:4000
frigate.chienlt.com         -> http://192.168.50.245:5000
plex.chienlt.com            -> http://192.168.50.242:32400
immich-server.chienlt.com   -> http://192.168.50.246:2283
kopia.chienlt.com           -> http://192.168.50.53:51515
```

Keep Docker-only apps on the wildcard fallback until we decide whether to keep or remove VM 121 internal Traefik.

---

## Task 5: Create Systemd Service

- [ ] **Step 1: Create `/etc/systemd/system/traefik.service`**

```ini
[Unit]
Description=Traefik edge reverse proxy
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/traefik/traefik.env
ExecStart=/usr/local/bin/traefik --configFile=/etc/traefik/traefik.yml
Restart=always
RestartSec=5
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 2: Enable and start**

```bash
systemctl daemon-reload
systemctl enable --now traefik.service
systemctl status traefik.service --no-pager
```

Expected: service is active.

---

## Task 6: Test Before DNS Cutover

- [ ] **Step 1: Test explicit route locally**

Run from any LAN host:

```bash
curl -k --resolve bambuddy.chienlt.com:443:192.168.50.54 \
  -I https://bambuddy.chienlt.com
```

Expected: HTTP 200 or app redirect from Bambuddy.

- [ ] **Step 2: Test Docker fallback route**

Use a Docker-label app that currently only VM 121 Traefik knows:

```bash
curl -k --resolve sonarr.chienlt.com:443:192.168.50.54 \
  -I https://sonarr.chienlt.com
```

Expected: VM121 internal Traefik routes it to Sonarr.

- [ ] **Step 3: Test one moved LXC route**

```bash
curl -k --resolve immich-server.chienlt.com:443:192.168.50.54 \
  -I https://immich-server.chienlt.com
```

Expected: response from Immich after adding the explicit edge route.

---

## Task 7: Cut Over DNS / Ingress

- [ ] **Step 1: Install and authorize Tailscale on `traefik-pve`**

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --ssh --hostname=traefik-pve
tailscale ip -4
```

Record the new tail IP.

- [ ] **Step 2: Update Cloudflare DNS**

Point wildcard/app records currently targeting VM 121 to the new `traefik-pve` target.

If using public LAN/NAT, update router port forwards:

```text
80/tcp  -> 192.168.50.54
443/tcp -> 192.168.50.54
```

If using Tailscale-only access, update the relevant DNS target to the new tail IP.

- [ ] **Step 3: Verify public routes**

```bash
curl -I https://bambuddy.chienlt.com
curl -I https://sonarr.chienlt.com
curl -I https://immich-server.chienlt.com
```

Expected: all route through `traefik-pve`.

---

## Task 8: Rollback

- [ ] **Step 1: Keep VM 121 Traefik unchanged until all checks pass**

Do not stop VM 121 Traefik during initial cutover.

- [ ] **Step 2: Revert DNS or NAT if needed**

Point records/ports back to VM 121:

```text
VM121 LAN:  192.168.50.121
VM121 tail: 100.81.144.82
```

- [ ] **Step 3: Stop edge LXC only after rollback**

```bash
ssh cle-pve 'pct stop 116'
```

---

## Optional Later Task: Remove VM121 Internal Traefik

Only do this if we accept the extra work.

To preserve Docker auto-routing with Traefik running only in the LXC, we need one of these designs:

1. Publish every routed Docker app port on VM 121 and configure Traefik Docker provider with `useBindPortIP=true`.
2. Create a routable Docker network that the LXC can reach.
3. Replace Docker-provider auto-routing with generated file-provider routes.

Option 1 is the most practical, but it increases the LAN-exposed surface of VM 121. Until there is a strong reason, keep VM 121 Traefik as the internal Docker router.
