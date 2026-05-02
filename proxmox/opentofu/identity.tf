locals {
  pulse_monitor_user_id    = "pulse-monitor@pam"
  pulse_monitor_token_name = "pulse-cle-pve-192-168-50-18"
}

resource "proxmox_virtual_environment_role" "pulse_monitor" {
  role_id = "PulseMonitor"

  privileges = [
    "Datastore.Audit",
    "Sys.Audit",
    "VM.GuestAgent.Audit",
    "VM.GuestAgent.FileRead",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_user" "pulse_monitor" {
  user_id = local.pulse_monitor_user_id
  comment = "Pulse monitoring service"
  enabled = true

  acl {
    path      = "/"
    role_id   = "PVEAuditor"
    propagate = true
  }

  acl {
    path      = "/"
    role_id   = proxmox_virtual_environment_role.pulse_monitor.role_id
    propagate = true
  }

  acl {
    path      = "/storage"
    role_id   = "PVEDatastoreAdmin"
    propagate = true
  }

  lifecycle {
    prevent_destroy = true
    # The live ACLs are documented here, but changing them requires
    # Permissions.Modify on "/" for the OpenTofu token. Keep that privilege out
    # of the routine provider account unless we intentionally widen it later.
    ignore_changes = [acl]
  }
}

resource "proxmox_user_token" "pulse_monitor" {
  user_id               = proxmox_virtual_environment_user.pulse_monitor.user_id
  token_name            = local.pulse_monitor_token_name
  privileges_separation = false

  lifecycle {
    prevent_destroy = true
  }
}
