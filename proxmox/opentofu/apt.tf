locals {
  proxmox_standard_repositories = {
    ceph_squid_enterprise = {
      handle    = "ceph-squid-enterprise"
      file_path = "/etc/apt/sources.list.d/ceph.sources"
      index     = 0
      enabled   = false
    }

    enterprise = {
      handle    = "enterprise"
      file_path = "/etc/apt/sources.list.d/pve-enterprise.sources"
      index     = 0
      enabled   = false
    }

    no_subscription = {
      handle    = "no-subscription"
      file_path = "/etc/apt/sources.list.d/proxmox.sources"
      index     = 0
      enabled   = true
    }

    test = {
      handle    = "test"
      file_path = "/etc/apt/sources.list.d/pve-test.sources"
      index     = 0
      enabled   = false
    }
  }
}

resource "proxmox_apt_standard_repository" "standard" {
  for_each = local.proxmox_standard_repositories

  handle = each.value.handle
  node   = local.node_name
}

resource "proxmox_apt_repository" "standard" {
  for_each = local.proxmox_standard_repositories

  enabled   = each.value.enabled
  file_path = each.value.file_path
  index     = each.value.index
  node      = local.node_name
}
