resource "proxmox_virtual_environment_vm" "qemu" {
  for_each = local.qemu_guests

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
