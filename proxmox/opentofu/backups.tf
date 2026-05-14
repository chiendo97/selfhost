resource "proxmox_backup_job" "nightly_guests" {
  id       = "nightly-guests"
  schedule = "03:30"
  storage  = "tank-backup"

  all            = true
  compress       = "zstd"
  enabled        = true
  mode           = "snapshot"
  node           = local.node_name
  notes_template = "{{guestname}}"
  prune_backups = {
    keep-daily   = "3"
    keep-monthly = "3"
    keep-weekly  = "4"
  }
  zstd = 1
}
