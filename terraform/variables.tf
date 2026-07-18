variable "pm_api_url" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID (e.g. admin@pve!terraform)"
  type        = string
  sensitive   = true
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "template_name" {
  description = "Name of the Proxmox VM template to clone from"
  type        = string
  default     = "debian13-cloudinit-template"
}

variable "target_node" {
  description = "Proxmox node to deploy VMs on"
  type        = string
  default     = "hp"
}

variable "vm_defaults" {
  description = "Default VM configuration"
  type = object({
    ciuser     = string
    cipassword = string
    agent      = bool
    onboot     = bool
    bridge     = string
  })
  default = {
    ciuser     = "admin"
    cipassword = "changeme"
    agent      = true
    onboot     = true
    bridge     = "vnet1"
  }
}

variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    cores   = number
    memory  = number
    disk_gb = number
  }))
  default = {
    prod = {
      cores   = 4
      memory  = 8192
      disk_gb = 50
    }
    dev = {
      cores   = 1
      memory  = 4096
      disk_gb = 25
    }
  }
}