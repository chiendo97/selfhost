locals {
  tailscale_stable_devices = {
    cle_viettel = {
      node_id             = "nosd1P9MZd11CNTRL"
      tags                = ["tag:server"]
      key_expiry_disabled = true
    }

    homelab_pve = {
      node_id             = "nuDA6dmzh511CNTRL"
      tags                = ["tag:trusted"]
      key_expiry_disabled = false
    }

    jellyfin_pve = {
      node_id             = "nXAtqsUpKk11CNTRL"
      tags                = ["tag:trusted"]
      key_expiry_disabled = true
    }

    n100 = {
      node_id             = "n3HGNPp9Nk11CNTRL"
      tags                = ["tag:trusted"]
      key_expiry_disabled = true
    }

    oracle = {
      node_id             = "nWvSuVVhZ321CNTRL"
      tags                = ["tag:server"]
      key_expiry_disabled = true
    }

    pulse_pve = {
      node_id             = "n4Y4Fn4TA611CNTRL"
      tags                = ["tag:server"]
      key_expiry_disabled = true
    }

    selfhost_pve = {
      node_id             = "nxFxxZ5oC311CNTRL"
      tags                = ["tag:trusted"]
      key_expiry_disabled = true
    }

    traefik_pve = {
      node_id             = "nKKyDKkqs521CNTRL"
      tags                = ["tag:trusted"]
      key_expiry_disabled = true
    }
  }

  tailscale_route_devices = {
    cle_viettel = {
      node_id = local.tailscale_stable_devices.cle_viettel.node_id
      routes  = ["0.0.0.0/0", "::/0"]
    }

    n100 = {
      node_id = local.tailscale_stable_devices.n100.node_id
      routes  = []
    }

    oracle = {
      node_id = local.tailscale_stable_devices.oracle.node_id
      routes  = ["0.0.0.0/0", "::/0"]
    }
  }
}

resource "tailscale_acl" "policy" {
  acl = file("${path.module}/tailscale-policy.hujson")
}

resource "tailscale_dns_configuration" "main" {
  magic_dns          = true
  override_local_dns = true
  search_paths       = []

  nameservers {
    address = "100.107.99.32"
  }

  nameservers {
    address = "100.79.39.73"
  }

  nameservers {
    address = "1.1.1.1"
  }
}

resource "tailscale_device_tags" "stable" {
  for_each = local.tailscale_stable_devices

  device_id = each.value.node_id
  tags      = each.value.tags
}

resource "tailscale_device_key" "stable" {
  for_each = local.tailscale_stable_devices

  device_id           = each.value.node_id
  key_expiry_disabled = each.value.key_expiry_disabled
}

resource "tailscale_device_subnet_routes" "stable" {
  for_each = local.tailscale_route_devices

  device_id = each.value.node_id
  routes    = each.value.routes
}
