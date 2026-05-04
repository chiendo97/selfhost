# Agent Guide

This repository is public. Treat every tracked file and every commit as
internet-visible.

Never commit credentials, runtime state, backup artifacts, app databases, logs,
`.env` files, `.tfstate`, `.tfvars`, private keys, `acme.json`, copied
Claude/Codex state, or generated service data.

## Read First

- `CLAUDE.md`: rootless Podman/Quadlet knowledge for the home automation stack.
- `proxmox/AGENTS.md`: Proxmox, OpenTofu, Tailscale, Cloudflare, and backup
  workflow guidance.
- `proxmox/README.md`: Proxmox documentation map.
- `proxmox/CURRENT_STATE.md`: live infrastructure source of truth.

## Worktree Safety

- The worktree may already contain user edits. Check `git status --short` and
  inspect diffs before editing.
- Do not revert or overwrite changes you did not make.
- Prefer `rg` for search.
- Use `apply_patch` for manual file edits.
- Do not run destructive commands such as `git reset --hard`, `git checkout --`
  on user files, dataset destroy, or guest destroy unless explicitly requested.

## Public Repo Checks

Before pushing, scan the exact tracked tree:

```bash
git status --short
git ls-files | rg -n '(^|/)(\.env|\.env\..*|.*\.env|.*\.pem|.*\.key|.*\.tfstate|.*\.tfvars|id_rsa|id_ed25519|acme\.json|.*sqlite.*|.*\.db)$' || true

tmp="$(mktemp -d)"
git ls-files -z | rsync -a --from0 --files-from=- ./ "$tmp"/
nix run nixpkgs#gitleaks -- dir "$tmp" --redact --verbose --no-banner
rm -rf "$tmp"
```

For a full history scan, archive each commit to a temp directory and run
`gitleaks dir` on the archive output. `gitleaks git` has reported `0 commits
scanned` in this repo, so do not trust that mode without checking its output.

## Root Stack

Root-level config tracks selected rootless Podman Quadlets. Runtime directories
and env files are ignored.

The live stack runs under `systemctl --user`, not plain `podman restart`:

```bash
systemctl --user daemon-reload
systemctl --user restart <name>
journalctl --user -u <name> -f
```

Important facts:

- `docker-compose.yml` is legacy for the root stack.
- Tracked Quadlet sources live under `quadlet/`.
- Home Assistant and matter-server rely on the custom D-Bus UID proxy described
  in `CLAUDE.md`.
- `podman restart <name>` can break Quadlet-managed services; use systemd.
- Bambuddy runs on host networking at port `8000`; Obico ML API runs on
  `127.0.0.1:3333`.

For docs-only changes outside OpenTofu, `git diff --check` is the minimum
verification. When pushing public changes, also run the tracked-tree secret
scan above.
