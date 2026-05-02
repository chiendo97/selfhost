import {
  to = proxmox_virtual_environment_vm.qemu["homelab_pve"]
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
  to = proxmox_virtual_environment_container.lxc["plex_pve"]
  id = "cle-pve/110"
}

import {
  to = proxmox_virtual_environment_container.lxc["jellyfin_pve"]
  id = "cle-pve/111"
}

import {
  to = proxmox_virtual_environment_container.lxc["nas_pve"]
  id = "cle-pve/112"
}

import {
  to = proxmox_virtual_environment_container.lxc["frigate_pve"]
  id = "cle-pve/113"
}

import {
  to = proxmox_virtual_environment_container.lxc["immich_pve"]
  id = "cle-pve/114"
}

import {
  to = proxmox_virtual_environment_container.lxc["backup_pve"]
  id = "cle-pve/115"
}
