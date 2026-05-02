resource "proxmox_virtual_environment_container" "lxc" {
  for_each = {
    for name, guest in local.lxc_guests : name => guest
    if name != "pulse"
  }

  node_name     = local.node_name
  vm_id         = each.value.vm_id
  description   = each.value.description
  tags          = each.value.tags
  started       = true
  start_on_boot = true
  unprivileged  = each.value.unprivileged

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
    swap      = each.value.swap
  }

  disk {
    datastore_id = each.value.rootfs_datastore
    size         = each.value.rootfs_size
  }

  initialization {
    hostname = each.value.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = each.value.mac_address
  }

  operating_system {
    template_file_id = var.default_lxc_template_file_id
    type             = "debian"
  }

  features {
    nesting = each.value.features.nesting
    keyctl  = each.value.features.keyctl
    fuse    = each.value.features.fuse
  }

  dynamic "mount_point" {
    for_each = each.value.mount_points

    content {
      volume    = mount_point.value.volume
      path      = mount_point.value.path
      read_only = mount_point.value.read_only
    }
  }

  dynamic "device_passthrough" {
    for_each = each.value.devices

    content {
      path = device_passthrough.value.path
      gid  = device_passthrough.value.gid
      mode = device_passthrough.value.mode
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

resource "proxmox_virtual_environment_container" "pulse" {
  node_name     = local.node_name
  vm_id         = local.lxc_guests.pulse.vm_id
  tags          = local.lxc_guests.pulse.tags
  started       = true
  start_on_boot = true
  unprivileged  = local.lxc_guests.pulse.unprivileged

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  memory {
    dedicated = local.lxc_guests.pulse.memory
    swap      = local.lxc_guests.pulse.swap
  }

  disk {
    datastore_id  = local.lxc_guests.pulse.rootfs_datastore
    mount_options = []
    replicate     = false
    size          = local.lxc_guests.pulse.rootfs_size
  }

  initialization {
    hostname = local.lxc_guests.pulse.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_interface {
    name         = "eth0"
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = local.lxc_guests.pulse.mac_address
    mtu          = 0
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    template_file_id = var.default_lxc_template_file_id
    type             = "debian"
  }

  startup {
    order      = local.lxc_guests.pulse.startup_order
    up_delay   = local.lxc_guests.pulse.startup_up_delay
    down_delay = -1
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      operating_system[0].template_file_id,
    ]
  }
}
