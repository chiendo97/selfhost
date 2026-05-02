# cle-pve OpenTofu

This directory is the first OpenTofu layer for the live `cle-pve` Proxmox
setup.

## Scope

Current scope is adoption only:

- import existing VM/LXC guests into local OpenTofu state;
- keep guest IDs, names, CPU, memory, root disk size, network, and startup
  metadata documented in HCL;
- prevent accidental destroy with `prevent_destroy = true`;
- ignore all live-resource changes with `ignore_changes = all` until adoption
  is proven safe.

OpenTofu does not yet own:

- ZFS pools or datasets;
- Proxmox storage definitions;
- backup jobs;
- LXC bind mounts as an enforcement mechanism;
- LXC device passthrough as an enforcement mechanism;
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
```

`OpenTofuAdoptDisk` only adds `VM.Config.Disk`, which the provider needs to
read imported VM disk metadata.

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

Once the imported state is stable, tighten ownership one guest class at a time:

1. Remove `ignore_changes = all` from one low-risk LXC.
2. Run `tofu plan`.
3. If the diff is only expected metadata, apply or adjust the HCL.
4. Repeat for the next guest.

Do not start with guests that have bind mounts or iGPU passthrough.
