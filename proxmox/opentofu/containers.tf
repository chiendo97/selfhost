resource "proxmox_virtual_environment_container" "app_igpu_lxc" {
  for_each = {
    frigate_pve = local.lxc_guests.frigate_pve
    immich_pve  = local.lxc_guests.immich_pve
  }

  node_name     = local.node_name
  vm_id         = each.value.vm_id
  tags          = each.value.tags
  started       = true
  start_on_boot = true
  unprivileged  = each.value.unprivileged

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    architecture = "amd64"
    cores        = each.value.cores
    limit        = 0
  }

  memory {
    dedicated = each.value.memory
    swap      = each.value.swap
  }

  disk {
    datastore_id  = each.value.rootfs_datastore
    mount_options = []
    replicate     = false
    size          = each.value.rootfs_size
  }

  initialization {
    hostname = each.value.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  dynamic "mount_point" {
    for_each = each.value.mount_points

    content {
      volume        = mount_point.value.volume
      path          = mount_point.value.path
      read_only     = mount_point.value.read_only
      backup        = false
      mount_options = []
      replicate     = true
      shared        = false
    }
  }

  dynamic "device_passthrough" {
    for_each = each.value.devices

    content {
      path       = device_passthrough.value.path
      gid        = device_passthrough.value.gid == null ? 0 : device_passthrough.value.gid
      uid        = 0
      mode       = device_passthrough.value.mode
      deny_write = false
    }
  }

  network_interface {
    name         = "eth0"
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = each.value.mac_address
    mtu          = 0
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    template_file_id = var.default_lxc_template_file_id
    type             = "debian"
  }

  startup {
    order      = each.value.startup_order
    up_delay   = each.value.startup_up_delay
    down_delay = -1
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      operating_system[0].template_file_id,
    ]
  }
}

resource "proxmox_virtual_environment_container" "media_igpu_lxc" {
  for_each = {
    plex_pve     = local.lxc_guests.plex_pve
    jellyfin_pve = local.lxc_guests.jellyfin_pve
  }

  node_name     = local.node_name
  vm_id         = each.value.vm_id
  tags          = each.value.tags
  started       = true
  start_on_boot = true
  unprivileged  = each.value.unprivileged

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    architecture = "amd64"
    cores        = each.value.cores
    limit        = 0
  }

  memory {
    dedicated = each.value.memory
    swap      = each.value.swap
  }

  disk {
    datastore_id  = each.value.rootfs_datastore
    mount_options = []
    replicate     = false
    size          = each.value.rootfs_size
  }

  initialization {
    hostname = each.value.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  mount_point {
    volume        = "/tank/media"
    path          = "/data"
    read_only     = true
    backup        = false
    mount_options = []
    replicate     = true
    shared        = false
  }

  dynamic "device_passthrough" {
    for_each = each.value.devices

    content {
      path       = device_passthrough.value.path
      gid        = device_passthrough.value.gid == null ? 0 : device_passthrough.value.gid
      uid        = 0
      mode       = device_passthrough.value.mode
      deny_write = false
    }
  }

  network_interface {
    name         = "eth0"
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = each.value.mac_address
    mtu          = 0
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    template_file_id = var.default_lxc_template_file_id
    type             = "debian"
  }

  startup {
    order      = each.value.startup_order
    up_delay   = each.value.startup_up_delay
    down_delay = -1
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      operating_system[0].template_file_id,
    ]
  }
}

resource "proxmox_virtual_environment_container" "backup_pve" {
  node_name     = local.node_name
  vm_id         = local.lxc_guests.backup_pve.vm_id
  tags          = local.lxc_guests.backup_pve.tags
  started       = true
  start_on_boot = true
  unprivileged  = local.lxc_guests.backup_pve.unprivileged

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    architecture = "amd64"
    cores        = local.lxc_guests.backup_pve.cores
    limit        = 0
  }

  memory {
    dedicated = local.lxc_guests.backup_pve.memory
    swap      = local.lxc_guests.backup_pve.swap
  }

  disk {
    datastore_id  = local.lxc_guests.backup_pve.rootfs_datastore
    mount_options = []
    replicate     = false
    size          = local.lxc_guests.backup_pve.rootfs_size
  }

  initialization {
    hostname = local.lxc_guests.backup_pve.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  mount_point {
    volume        = "/fast/immich-app"
    path          = "/source/immich-app"
    read_only     = true
    backup        = false
    mount_options = []
    replicate     = true
    shared        = false
  }

  mount_point {
    volume        = "/tank/fast-backups"
    path          = "/backups"
    read_only     = false
    backup        = false
    mount_options = []
    replicate     = true
    shared        = false
  }

  network_interface {
    name         = "eth0"
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = local.lxc_guests.backup_pve.mac_address
    mtu          = 0
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    template_file_id = var.default_lxc_template_file_id
    type             = "debian"
  }

  startup {
    order      = local.lxc_guests.backup_pve.startup_order
    up_delay   = local.lxc_guests.backup_pve.startup_up_delay
    down_delay = -1
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      operating_system[0].template_file_id,
    ]
  }
}

resource "proxmox_virtual_environment_container" "nas_pve" {
  node_name     = local.node_name
  vm_id         = local.lxc_guests.nas_pve.vm_id
  tags          = local.lxc_guests.nas_pve.tags
  started       = true
  start_on_boot = true
  unprivileged  = local.lxc_guests.nas_pve.unprivileged

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  memory {
    dedicated = local.lxc_guests.nas_pve.memory
    swap      = local.lxc_guests.nas_pve.swap
  }

  disk {
    datastore_id  = local.lxc_guests.nas_pve.rootfs_datastore
    mount_options = []
    replicate     = false
    size          = local.lxc_guests.nas_pve.rootfs_size
  }

  initialization {
    hostname = local.lxc_guests.nas_pve.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  dynamic "mount_point" {
    for_each = local.lxc_guests.nas_pve.mount_points

    content {
      volume        = mount_point.value.volume
      path          = mount_point.value.path
      read_only     = mount_point.value.read_only
      backup        = false
      mount_options = []
      replicate     = true
      shared        = false
    }
  }

  network_interface {
    name         = "eth0"
    bridge       = "vmbr0"
    enabled      = true
    firewall     = false
    host_managed = false
    mac_address  = local.lxc_guests.nas_pve.mac_address
    mtu          = 0
    rate_limit   = 0
    vlan_id      = 0
  }

  operating_system {
    template_file_id = var.default_lxc_template_file_id
    type             = "debian"
  }

  startup {
    order      = local.lxc_guests.nas_pve.startup_order
    up_delay   = local.lxc_guests.nas_pve.startup_up_delay
    down_delay = -1
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      operating_system[0].template_file_id,
    ]
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

  dynamic "device_passthrough" {
    for_each = local.lxc_guests.pulse.devices

    content {
      path       = device_passthrough.value.path
      gid        = device_passthrough.value.gid == null ? 0 : device_passthrough.value.gid
      uid        = 0
      mode       = device_passthrough.value.mode
      deny_write = false
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
