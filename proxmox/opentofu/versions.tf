terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.104.0"
    }

    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.28.0"
    }
  }
}
