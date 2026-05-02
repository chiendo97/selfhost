resource "proxmox_storage_directory" "local" {
  id     = "local"
  path   = "/var/lib/vz"
  shared = false

  content = ["backup", "import", "iso", "vztmpl"]
}

resource "proxmox_storage_directory" "tank_backup" {
  id     = "tank-backup"
  path   = "/tank/pve-backups"
  shared = false

  content = ["backup"]
}

resource "proxmox_storage_zfspool" "local_zfs" {
  id       = "local-zfs"
  zfs_pool = "rpool/data"

  content        = ["images", "rootdir"]
  thin_provision = true
}

resource "proxmox_storage_zfspool" "fast_vm" {
  id       = "fast-vm"
  zfs_pool = "fast/vm"

  content        = ["images", "rootdir"]
  thin_provision = true
}
