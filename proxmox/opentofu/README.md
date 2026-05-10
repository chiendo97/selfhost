# cle-pve OpenTofu

This directory is the first OpenTofu layer for the live `cle-pve` Proxmox
setup.

## Scope

Current scope:

- all existing guests are imported into local OpenTofu state;
- all current LXCs and both NixOS VMs are tightened and plan no changes without
  blanket `ignore_changes = all`;
- the live Tailscale tailnet policy is imported and managed from
  `tailscale-policy.hujson`;
- Tailscale DNS config, stable infra device tags, and stable infra key-expiry
  settings are imported and plan no changes;
- Tailscale subnet/exit route enablement for selected stable infra devices is
  imported and plans no changes;
- the current Proxmox backup job, storage definitions, and Proxmox APT
  repository enablement are imported and plan no changes;
- the Pulse-created Proxmox monitoring identity is imported and protected from
  destroy;
- current `chienlt.com` Cloudflare DNS records are imported and plan no
  changes;
- all guest resources use `prevent_destroy = true`.

OpenTofu does not yet own:

- ZFS pools or datasets;
- host package installation, system services, zram, sysctl, or ZFS dataset
  properties;
- Tailscale device lifecycle, auth keys, or device authorization;
- NixOS, Home Manager, Docker, Traefik, Homepage, or app config.

Those stay in the current manual/docs flow until the later Ansible layer is
added.

## Credentials

Do not put credentials in `.tfvars` committed to git.

Use the provider's environment variables:

```bash
export PROXMOX_VE_API_TOKEN='user@realm!tokenid=token-secret'
export TAILSCALE_API_KEY='tskey-api-...'
export CLOUDFLARE_API_TOKEN='...'
```

Current local setup uses `opentofu@pve!cle-pve-adopt`. The Proxmox token secret
is in ignored `.env.local` on this workstation only. The Cloudflare and
Tailscale provider tokens are also available in ignored `.env.local`; source
copies remain in ignored `../.env`. On `cle-pve`, `opentofu@pve` has:

```text
PVEAuditor
OpenTofuAdoptDisk
OpenTofuHomelabManage on /vms/101
OpenTofuSelfhostManage on /vms/121
OpenTofuPulseManage on /vms/102
OpenTofuPlexManage on /vms/110
OpenTofuJellyfinManage on /vms/111
OpenTofuNasManage on /vms/112
OpenTofuFrigateManage on /vms/113
OpenTofuImmichManage on /vms/114
OpenTofuBackupManage on /vms/115
OpenTofuTraefikManage on /vms/116
OpenTofuStorageManage on /storage/local
OpenTofuStorageManage on /storage/local-zfs
OpenTofuStorageManage on /storage/fast-vm
OpenTofuStorageManage on /storage/tank-backup
OpenTofuIdentityManage on /access
PulseMonitor
pulse-monitor@pam
pulse-monitor@pam!pulse-cle-pve-192-168-50-18
```

`OpenTofuAdoptDisk` only adds `VM.Config.Disk`, which the provider needs to
read imported VM disk metadata.

The CT-scoped manage roles only add `VM.Audit,VM.Config.Options`, which is
enough to apply provider normalization for the current LXCs without broad VM
admin privileges. `OpenTofuPulseManage` also includes `VM.Config.Memory` on
`/vms/102` so OpenTofu can adjust the Pulse LXC memory limit.

The VM 101-scoped manage role adds
`VM.Audit,VM.Config.Disk,VM.Config.Options,VM.GuestAgent.Audit` on its VM path.
The VM 121-scoped manage role also includes `VM.Config.Memory` so OpenTofu can
apply memory-limit changes. They intentionally do not include `VM.PowerMgmt`,
so this OpenTofu token cannot shut down or restart the NixOS VMs.

`OpenTofuStorageManage` adds `Datastore.Allocate,Datastore.Audit` on each
adopted storage path. The provider requires `Datastore.Allocate` even to read
those storage resources.

`OpenTofuIdentityManage` adds `User.Modify` on `/access` so the provider can
refresh imported Proxmox user-token metadata. It does not include
`Permissions.Modify`; routine OpenTofu runs cannot change cluster ACL bindings.

`PulseMonitor` is owned for the Pulse monitoring user and contains
`Datastore.Audit,Sys.Audit,VM.GuestAgent.Audit,VM.GuestAgent.FileRead`.
`pulse-monitor@pam` also has `PVEAuditor` on `/` and `PVEDatastoreAdmin` on
`/storage`. Those live ACLs are documented in `identity.tf`, but ACL drift is
ignored because changing them would require `Permissions.Modify` on `/`. The API
token resource is imported as metadata only; the token secret is not committed
to git.

The default endpoint is:

```text
https://192.168.50.13:8006/
```

## State

This first pass uses the default local OpenTofu backend. The state file is
ignored by git:

```text
terraform.tfstate
```

Move state to a backed-up or remote backend before relying on OpenTofu as the
only source of truth.

Current local state backup:

```text
cle-pve:/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-200900
cle-pve:/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260508-232851
```

The backup directory is root-owned and mode `0700`. A matching `.sha256` file
exists next to the state backup.

## First Adoption

Run from this directory:

```bash
tofu init
tofu plan -out adopt.plan
```

If `tofu` is not installed on the host, use Nix:

```bash
nix run nixpkgs#opentofu -- init
nix run nixpkgs#opentofu -- plan -out adopt.plan
```

The expected first plan should show imports for:

```text
101 homelab-pve
121 selfhost-pve
102 pulse
110 plex-pve
111 jellyfin-pve
112 nas-pve
113 frigate-pve
114 immich-pve
115 backup-pve
116 traefik-pve
```

Do not apply if the plan wants to create, replace, or destroy any guest.

If the plan is import-only, apply it:

```bash
tofu apply adopt.plan
tofu plan
```

The second `tofu plan` should be no-op or limited to understood provider
metadata noise. Keep `ignore_changes = all` until that is true.

This was completed locally on 2026-05-01: 9 guests imported, 0 added, 0 changed,
0 destroyed, and the follow-up plan was no-op.

The Tailscale ACL resource was adopted on 2026-05-02 with one import, 0 added,
0 changed, 0 destroyed, and a no-op follow-up plan.

Tailscale DNS config plus stable device tags and key-expiry settings were
adopted on 2026-05-02 with 13 imports, 0 added, 0 changed, 0 destroyed, and a
no-op follow-up plan.

Proxmox backup/storage/APT settings plus selected Tailscale route enablement
were adopted on 2026-05-02 with 16 imports, 0 added, 0 changed, 0 destroyed, and
a no-op follow-up plan.

The current `chienlt.com` Cloudflare DNS records were adopted on 2026-05-02
with 9 imports, 0 added, 0 changed, 0 destroyed, and a no-op follow-up plan.

## After Adoption

The current LXC tightening pass is complete. All current LXCs plan no changes
without blanket `ignore_changes = all`:

```text
102 pulse
110 plex-pve
111 jellyfin-pve
112 nas-pve
113 frigate-pve
114 immich-pve
115 backup-pve
```

Both NixOS VMs have also been split into dedicated tightened resources and plan
no changes without blanket `ignore_changes = all`:

```text
101 homelab-pve
121 selfhost-pve
```

OpenTofu owns the normal provider-visible LXC inventory fields, including CPU,
memory, rootfs size, mounts, device passthrough, network, startup order, and
on-boot behavior.

Targeted LXC ignores remain:

- `description`, because the live community-script HTML is noisy and not useful
  as desired configuration. This applies only to CT 102 `pulse`.
- `operating_system[0].template_file_id`, because the provider requires a
  template for create but imported containers do not keep that template in live
  state.

Each tightened LXC has a CT-scoped Proxmox role with
`VM.Audit,VM.Config.Options` so OpenTofu can apply provider normalization without
granting broad VM admin privileges.

Targeted VM ignores remain:

- `disk[0].path_in_datastore`, because that is provider/import metadata for the
  existing disk rather than desired configuration.
- VM 121 `description`, because the live NixOS-generated description includes a
  leading space.
- VM 121 `keyboard_layout` and `agent[0].type`, because normalizing those
  provider defaults previously caused the provider to request VM shutdown.

## Tailscale Ownership

`tailscale_acl.policy` manages the full tailnet policy from:

```text
tailscale-policy.hujson
```

This is whole-file ownership. Manual ACL edits in the Tailscale admin console or
through the API will show as drift on the next `tofu plan`; if those edits are
intended, pull them back into `tailscale-policy.hujson` before applying other
OpenTofu changes.

`tailscale_dns_configuration.main` manages the full tailnet DNS config:

```text
MagicDNS: true
Override local DNS: true
Nameservers: 100.107.99.32, 100.79.39.73, 1.1.1.1
Search paths: none
```

The provider currently warns that `tailscale_dns_configuration` is alpha.

OpenTofu also manages tags and key-expiry settings for these stable devices:

```text
cle_viettel
homelab_pve
jellyfin_pve
n100
nas_pve
oracle
pulse_pve
selfhost_pve
traefik_pve
```

OpenTofu also manages subnet/exit route enablement for:

```text
cle_viettel: 0.0.0.0/0, ::/0
oracle: 0.0.0.0/0, ::/0
n100: none enabled
```

Device onboarding, auth keys, device authorization, route advertisement on the
hosts, and host runtime Tailscale config are still managed outside OpenTofu.

## Cloudflare DNS

OpenTofu tracks the current `chienlt.com` Cloudflare DNS records:

```text
*.chienlt.com: A 100.112.33.84
chienlt.com: A 100.104.100.77
adguard.chienlt.com: A 100.107.99.32
adguard-oracle.chienlt.com: A 168.138.176.219
bazarr.chienlt.com: A 171.244.62.91
jellyfin.chienlt.com: A 171.244.62.91
jellyseerr.chienlt.com: A 171.244.62.91
plex.chienlt.com: A 100.112.33.84
amz.chienlt.com: CNAME 9315ec0b-64d4-4744-a743-7bb0c2e35e45.cfargotunnel.com, proxied
```

All direct records pointing to tailnet IPs are intentionally unproxied because
Cloudflare's proxy cannot reach private Tailscale addresses.

## Proxmox Platform

OpenTofu tracks the current Proxmox platform-level resources:

```text
Backup job: nightly-guests
Storage: local, local-zfs, fast-vm, tank-backup
APT standard repos: no-subscription enabled; enterprise, test, ceph-squid-enterprise disabled
Pulse monitoring identity: pulse-monitor@pam, PulseMonitor role, pulse-monitor@pam!pulse-cle-pve-192-168-50-18 token
```

`tank-backup` storage prune settings are intentionally not represented in this
first storage adoption because the provider wanted to rewrite them even though
the live storage already has matching retention. Guest backup retention is still
represented on `proxmox_backup_job.nightly_guests`.
