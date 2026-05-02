# Repository Guidelines

## Project Structure & Module Organization

This directory is a single OpenTofu root for the live `cle-pve` Proxmox layer.
Resources are grouped by ownership area:

- `versions.tf`, `providers.tf`, and `variables.tf` define OpenTofu, provider,
  and input settings.
- `locals.tf` holds guest inventory data for QEMU VMs and LXCs.
- `containers.tf`, `vms.tf`, `storage.tf`, `backups.tf`, `apt.tf`,
  `identity.tf`, `tailscale.tf`, and `cloudflare.tf` manage the live resources.
- `imports.tf` tracks import and moved-block history.
- `tailscale-policy.hujson` is the full managed Tailscale ACL policy.

There are no application assets or unit-test directories. Local state, plans,
credentials, and overrides are intentionally ignored.

## Build, Test, and Development Commands

- `tofu init`: install providers and prepare `.terraform/`.
- `tofu fmt -recursive`: format all OpenTofu files.
- `tofu validate`: check configuration syntax and provider schema.
- `tofu plan -out change.plan`: create a reviewable plan before applying.
- `tofu apply change.plan`: apply only a previously reviewed plan.

If OpenTofu is not installed, use `nix run nixpkgs#opentofu -- <command>`.

## Coding Style & Naming Conventions

Use standard OpenTofu formatting: two-space indentation, aligned arguments after
`tofu fmt`, and snake_case for locals, variables, and resource names
(`local.lxc_guests`, `proxmox_backup_job.nightly_guests`). Keep guest inventory
changes in `locals.tf` when possible, and keep resource behavior in the
resource-specific `.tf` file. Prefer targeted `ignore_changes` entries with a
comment in `README.md` over broad lifecycle ignores.

## Testing Guidelines

There is no separate test framework. Treat `tofu fmt -check -recursive`,
`tofu validate`, and `tofu plan` as the required checks. For this live
infrastructure repo, a safe plan should not create, replace, or destroy guests
unless the change explicitly requires it. Preserve `prevent_destroy = true` on
guest resources.

## Commit & Pull Request Guidelines

Recent history uses short imperative commits, often with conventional prefixes
such as `chore:` and `docs:`. Examples: `docs: update pulse monitoring state`,
`chore: manage cloudflare dns with opentofu`.

Pull requests should include the reason for the infrastructure change, the
commands run, and a summary of the resulting plan. Call out any expected drift,
imports, moved blocks, or destructive actions.

## Security & Configuration Tips

Never commit `.env*`, `*.tfvars`, `terraform.tfstate*`, or `*.plan` files.
Provider credentials should come from environment variables such as
`PROXMOX_VE_API_TOKEN`, `TAILSCALE_API_KEY`, and `CLOUDFLARE_API_TOKEN`.
Back up local state before relying on it for recovery or applying risky plans.
