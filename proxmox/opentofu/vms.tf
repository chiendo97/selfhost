resource "proxmox_virtual_environment_vm" "qemu" {
  for_each = {
    for name, guest in local.qemu_guests : name => guest
    if name != "homelab_pve"
  }

  node_name   = local.node_name
  vm_id       = each.value.vm_id
  name        = each.value.name
  description = each.value.description

  bios       = "seabios"
  boot_order = ["virtio0"]
  on_boot    = true
  started    = true

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = each.value.boot_disk_datastore
    interface    = "virtio0"
    size         = each.value.boot_disk_size
  }

  initialization {
    datastore_id = each.value.cloudinit_datastore
    interface    = "ide2"
  }

  network_device {
    bridge      = "vmbr0"
    firewall    = true
    mac_address = each.value.mac_address
    model       = "virtio"
  }

  operating_system {
    type = "l26"
  }

  scsi_hardware = "virtio-scsi-single"

  serial_device {
    device = "socket"
  }

  dynamic "vga" {
    for_each = each.value.vga_type == null ? [] : [each.value.vga_type]

    content {
      type = vga.value
    }
  }

  startup {
    order      = each.value.startup_order
    up_delay   = each.value.startup_up_delay
    down_delay = each.value.startup_down_delay
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

resource "proxmox_virtual_environment_vm" "homelab_pve" {
  node_name   = local.node_name
  vm_id       = local.qemu_guests.homelab_pve.vm_id
  name        = local.qemu_guests.homelab_pve.name
  description = local.qemu_guests.homelab_pve.description

  acpi                                 = true
  bios                                 = "seabios"
  boot_order                           = ["virtio0"]
  delete_unreferenced_disks_on_destroy = true
  keyboard_layout                      = "en-us"
  migrate                              = false
  on_boot                              = true
  protection                           = false
  purge_on_destroy                     = true
  reboot                               = false
  reboot_after_update                  = true
  scsi_hardware                        = "virtio-scsi-single"
  started                              = true
  stop_on_destroy                      = false
  tablet_device                        = true
  tags                                 = []
  template                             = false
  timeout_clone                        = 1800
  timeout_create                       = 1800
  timeout_migrate                      = 1800
  timeout_reboot                       = 1800
  timeout_shutdown_vm                  = 1800
  timeout_start_vm                     = 1800
  timeout_stop_vm                      = 300

  agent {
    enabled = true
    timeout = "15m"
    trim    = false
    type    = "virtio"
  }

  cpu {
    cores   = local.qemu_guests.homelab_pve.cores
    flags   = []
    limit   = 0
    numa    = false
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated      = local.qemu_guests.homelab_pve.memory
    floating       = 0
    keep_hugepages = false
    shared         = 0
  }

  disk {
    aio          = "io_uring"
    backup       = true
    cache        = "none"
    datastore_id = local.qemu_guests.homelab_pve.boot_disk_datastore
    discard      = "ignore"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = false
    replicate    = true
    size         = local.qemu_guests.homelab_pve.boot_disk_size
    ssd          = false
  }

  initialization {
    datastore_id = local.qemu_guests.homelab_pve.cloudinit_datastore
    interface    = "ide2"
    upgrade      = true
  }

  network_device {
    bridge       = "vmbr0"
    disconnected = false
    firewall     = true
    mac_address  = local.qemu_guests.homelab_pve.mac_address
    model        = "virtio"
    mtu          = 0
    queues       = 0
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  startup {
    order      = local.qemu_guests.homelab_pve.startup_order
    up_delay   = local.qemu_guests.homelab_pve.startup_up_delay
    down_delay = -1
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      disk[0].path_in_datastore,
    ]
  }
}
