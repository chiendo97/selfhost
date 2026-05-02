moved {
  from = proxmox_virtual_environment_container.lxc["pulse"]
  to   = proxmox_virtual_environment_container.pulse
}

moved {
  from = proxmox_virtual_environment_container.lxc["nas_pve"]
  to   = proxmox_virtual_environment_container.nas_pve
}

moved {
  from = proxmox_virtual_environment_container.lxc["backup_pve"]
  to   = proxmox_virtual_environment_container.backup_pve
}

moved {
  from = proxmox_virtual_environment_container.lxc["plex_pve"]
  to   = proxmox_virtual_environment_container.media_igpu_lxc["plex_pve"]
}

moved {
  from = proxmox_virtual_environment_container.lxc["jellyfin_pve"]
  to   = proxmox_virtual_environment_container.media_igpu_lxc["jellyfin_pve"]
}

moved {
  from = proxmox_virtual_environment_container.lxc["frigate_pve"]
  to   = proxmox_virtual_environment_container.app_igpu_lxc["frigate_pve"]
}

moved {
  from = proxmox_virtual_environment_container.lxc["immich_pve"]
  to   = proxmox_virtual_environment_container.app_igpu_lxc["immich_pve"]
}

moved {
  from = proxmox_virtual_environment_vm.qemu["homelab_pve"]
  to   = proxmox_virtual_environment_vm.homelab_pve
}
