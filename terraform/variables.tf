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
      cores   = 2
      memory  = 4096
      disk_gb = 25
    }
  }
}

variable "create_vms" {
  description = "When true, provision fresh VMs by cloning the template (clone block applied). When false (default), manage existing/imported VMs in place and omit the clone block so Terraform does not force a destroy-and-recreate."
  type        = bool
  default     = false
}

variable "vm_power_state" {
  description = "Desired power state per VM, keyed by VM name. Valid values: \"started\" (power on and auto-start on host boot) or \"stopped\" (power off and do not auto-start on host reboot)."
  type        = map(string)
  default = {
    prod = "started"
    dev  = "stopped"
  }
  validation {
    condition = alltrue([
      for s in values(var.vm_power_state) : contains(["started", "stopped"], s)
    ])
    error_message = "Each vm_power_state value must be either \"started\" or \"stopped\"."
  }
}
