variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint for cle-pve."
  type        = string
  default     = "https://192.168.50.13:8006/"
}

variable "proxmox_insecure" {
  description = "Allow the current self-signed Proxmox certificate."
  type        = bool
  default     = true
}

variable "default_lxc_template_file_id" {
  description = "Fallback LXC template file ID required by the provider schema. Existing imported CTs will not be recreated from this template."
  type        = string
  default     = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
}
