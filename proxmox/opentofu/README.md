# cle-pve OpenTofu

This directory is the first OpenTofu layer for the live `cle-pve` Proxmox
setup.

## Scope

Current scope:

- all existing guests are imported into local OpenTofu state;
- all current LXCs and both NixOS VMs are tightened and plan no changes without
  blanket `ignore_changes = all`;
- all guest resources use `prevent_destroy = true`.

OpenTofu does not yet own:

- ZFS pools or datasets;
- Proxmox storage definitions;
- backup jobs;
- NixOS, Home Manager, Docker, Traefik, Homepage, or app config.

Those stay in the current manual/docs flow until the later Ansible layer is
added.

## Credentials

Do not put credentials in `.tfvars` committed to git.

Use the provider's environment variables:

```bash
export PROXMOX_VE_API_TOKEN='user@realm!tokenid=token-secret'
```

Current local setup uses `opentofu@pve!cle-pve-adopt`. The token secret is in
ignored `.env.local` on this workstation only. On `cle-pve`, `opentofu@pve`
has:

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
```

`OpenTofuAdoptDisk` only adds `VM.Config.Disk`, which the provider needs to
read imported VM disk metadata.

The CT-scoped manage roles only add `VM.Audit,VM.Config.Options`, which was
enough to apply provider normalization for the current LXCs without broad VM
admin privileges.

The VM-scoped manage roles add
`VM.Audit,VM.Config.Disk,VM.Config.Options,VM.GuestAgent.Audit` on their VM
paths. They intentionally do not include `VM.PowerMgmt`, so this OpenTofu token
cannot shut down or restart the NixOS VMs.

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
cle-pve:/tank/fast-backups/opentofu/cle-pve/terraform.tfstate.20260502-115927
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
