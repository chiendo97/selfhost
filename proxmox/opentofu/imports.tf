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
