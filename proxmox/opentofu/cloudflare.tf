locals {
  cloudflare_zone_id = "5f2460ae1b6c01224007c6013a62beb3"

  cloudflare_dns_records = {
    wildcard = {
      name    = "*.chienlt.com"
      type    = "A"
      content = "100.81.144.82"
      proxied = false
      ttl     = 1
    }

    apex = {
      name    = "chienlt.com"
      type    = "A"
      content = "100.104.100.77"
      proxied = false
      ttl     = 1
    }

    adguard = {
      name    = "adguard.chienlt.com"
      type    = "A"
      content = "100.107.99.32"
      proxied = false
      ttl     = 1
    }

    adguard_oracle = {
      name    = "adguard-oracle.chienlt.com"
      type    = "A"
      content = "168.138.176.219"
      proxied = false
      ttl     = 1
    }

    bazarr = {
      name    = "bazarr.chienlt.com"
      type    = "A"
      content = "171.244.62.91"
      proxied = false
      ttl     = 1
    }

    jellyfin = {
      name    = "jellyfin.chienlt.com"
      type    = "A"
      content = "171.244.62.91"
      proxied = false
      ttl     = 1
    }

    jellyseerr = {
      name    = "jellyseerr.chienlt.com"
      type    = "A"
      content = "171.244.62.91"
      proxied = false
      ttl     = 1
    }

    plex = {
      name    = "plex.chienlt.com"
      type    = "A"
      content = "100.81.144.82"
      proxied = false
      ttl     = 1
    }
  }
}

resource "cloudflare_dns_record" "chienlt" {
  for_each = local.cloudflare_dns_records

  zone_id = local.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = each.value.ttl
}
