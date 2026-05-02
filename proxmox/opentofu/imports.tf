import {
  to = proxmox_virtual_environment_vm.homelab_pve
  id = "cle-pve/101"
}

import {
  to = proxmox_virtual_environment_vm.selfhost_pve
  id = "cle-pve/121"
}

import {
  to = proxmox_virtual_environment_container.pulse
  id = "cle-pve/102"
}

import {
  to = proxmox_virtual_environment_container.media_igpu_lxc["plex_pve"]
  id = "cle-pve/110"
}

import {
  to = proxmox_virtual_environment_container.media_igpu_lxc["jellyfin_pve"]
  id = "cle-pve/111"
}

import {
  to = proxmox_virtual_environment_container.nas_pve
  id = "cle-pve/112"
}

import {
  to = proxmox_virtual_environment_container.app_igpu_lxc["frigate_pve"]
  id = "cle-pve/113"
}

import {
  to = proxmox_virtual_environment_container.app_igpu_lxc["immich_pve"]
  id = "cle-pve/114"
}

import {
  to = proxmox_virtual_environment_container.backup_pve
  id = "cle-pve/115"
}

import {
  to = tailscale_acl.policy
  id = "acl"
}

import {
  to = tailscale_dns_configuration.main
  id = "dns_configuration"
}

import {
  to = tailscale_device_tags.stable["cle_viettel"]
  id = "nosd1P9MZd11CNTRL"
}

import {
  to = tailscale_device_tags.stable["homelab_pve"]
  id = "nuDA6dmzh511CNTRL"
}

import {
  to = tailscale_device_tags.stable["jellyfin_pve"]
  id = "nXAtqsUpKk11CNTRL"
}

import {
  to = tailscale_device_tags.stable["n100"]
  id = "n3HGNPp9Nk11CNTRL"
}

import {
  to = tailscale_device_tags.stable["oracle"]
  id = "nWvSuVVhZ321CNTRL"
}

import {
  to = tailscale_device_tags.stable["selfhost_pve"]
  id = "nxFxxZ5oC311CNTRL"
}

import {
  to = tailscale_device_key.stable["cle_viettel"]
  id = "nosd1P9MZd11CNTRL"
}

import {
  to = tailscale_device_key.stable["homelab_pve"]
  id = "nuDA6dmzh511CNTRL"
}

import {
  to = tailscale_device_key.stable["jellyfin_pve"]
  id = "nXAtqsUpKk11CNTRL"
}

import {
  to = tailscale_device_key.stable["n100"]
  id = "n3HGNPp9Nk11CNTRL"
}

import {
  to = tailscale_device_key.stable["oracle"]
  id = "nWvSuVVhZ321CNTRL"
}

import {
  to = tailscale_device_key.stable["selfhost_pve"]
  id = "nxFxxZ5oC311CNTRL"
}

import {
  to = proxmox_backup_job.nightly_guests
  id = "nightly-guests"
}

import {
  to = proxmox_virtual_environment_role.pulse_monitor
  id = "PulseMonitor"
}

import {
  to = proxmox_virtual_environment_user.pulse_monitor
  id = "pulse-monitor@pam"
}

import {
  to = proxmox_user_token.pulse_monitor
  id = "pulse-monitor@pam!pulse-cle-pve-192-168-50-18"
}

import {
  to = proxmox_storage_directory.local
  id = "local"
}

import {
  to = proxmox_storage_directory.tank_backup
  id = "tank-backup"
}

import {
  to = proxmox_storage_zfspool.local_zfs
  id = "local-zfs"
}

import {
  to = proxmox_storage_zfspool.fast_vm
  id = "fast-vm"
}

import {
  to = proxmox_apt_standard_repository.standard["ceph_squid_enterprise"]
  id = "cle-pve,ceph-squid-enterprise"
}

import {
  to = proxmox_apt_standard_repository.standard["enterprise"]
  id = "cle-pve,enterprise"
}

import {
  to = proxmox_apt_standard_repository.standard["no_subscription"]
  id = "cle-pve,no-subscription"
}

import {
  to = proxmox_apt_standard_repository.standard["test"]
  id = "cle-pve,test"
}

import {
  to = proxmox_apt_repository.standard["ceph_squid_enterprise"]
  id = "cle-pve,/etc/apt/sources.list.d/ceph.sources,0"
}

import {
  to = proxmox_apt_repository.standard["enterprise"]
  id = "cle-pve,/etc/apt/sources.list.d/pve-enterprise.sources,0"
}

import {
  to = proxmox_apt_repository.standard["no_subscription"]
  id = "cle-pve,/etc/apt/sources.list.d/proxmox.sources,0"
}

import {
  to = proxmox_apt_repository.standard["test"]
  id = "cle-pve,/etc/apt/sources.list.d/pve-test.sources,0"
}

import {
  to = tailscale_device_subnet_routes.stable["cle_viettel"]
  id = "nosd1P9MZd11CNTRL"
}

import {
  to = tailscale_device_subnet_routes.stable["n100"]
  id = "n3HGNPp9Nk11CNTRL"
}

import {
  to = tailscale_device_subnet_routes.stable["oracle"]
  id = "nWvSuVVhZ321CNTRL"
}

import {
  to = cloudflare_dns_record.chienlt["wildcard"]
  id = "5f2460ae1b6c01224007c6013a62beb3/7d0067152e199a9bb3f9f90532f521ac"
}

import {
  to = cloudflare_dns_record.chienlt["apex"]
  id = "5f2460ae1b6c01224007c6013a62beb3/c71b8e41b5d46c0491d5a25a86d75d9c"
}

import {
  to = cloudflare_dns_record.chienlt["adguard"]
  id = "5f2460ae1b6c01224007c6013a62beb3/7ca9026f828f6d4496ff3ed20ee7b1e9"
}

import {
  to = cloudflare_dns_record.chienlt["adguard_oracle"]
  id = "5f2460ae1b6c01224007c6013a62beb3/8c341e4cf5db419a29935ce54d7faee8"
}

import {
  to = cloudflare_dns_record.chienlt["bazarr"]
  id = "5f2460ae1b6c01224007c6013a62beb3/21e17fd61a3ee4d95512bd455bbdce41"
}

import {
  to = cloudflare_dns_record.chienlt["jellyfin"]
  id = "5f2460ae1b6c01224007c6013a62beb3/f25ade90509448ab3f3dfc0741b9f70a"
}

import {
  to = cloudflare_dns_record.chienlt["jellyseerr"]
  id = "5f2460ae1b6c01224007c6013a62beb3/725faac225d860025c65ce1c71bb7b36"
}

import {
  to = cloudflare_dns_record.chienlt["plex"]
  id = "5f2460ae1b6c01224007c6013a62beb3/1cf23463a03eaa7ed18dd8da5953eaee"
}
