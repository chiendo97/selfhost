import {
  to = proxmox_virtual_environment_vm.homelab_pve
  id = "cle-pve/101"
}

import {
  to = proxmox_virtual_environment_vm.qemu["selfhost_pve"]
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
