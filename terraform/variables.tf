variable "pm_api_url" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "pm_api_username" {
  description = "Proxmox API username (e.g. admin@pve)"
  type        = string
  sensitive   = true
}

variable "pm_api_password" {
  description = "Proxmox API password"
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
  description = "Map of VMs to create. Each VM can optionally specify port forwards for NAT iptables rules on the Proxmox host."
  type = map(object({
    vm_id   = number
    cores   = number
    memory  = number
    disk_gb = number
    forwards = list(object({
      protocol      = string
      public_port   = number
      internal_port = number
    }))
  }))
  default = {
    prod = {
      vm_id   = 200
      cores   = 4
      memory  = 8192
      disk_gb = 50
      forwards = [
        { protocol = "tcp", public_port = 8080, internal_port = 8080 }
      ]
    }
    dev = {
      vm_id    = 201
      cores    = 2
      memory   = 4096
      disk_gb  = 25
      forwards = []
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

variable "ssh_public_keys" {
  description = "SSH public key(s) injected into the cloud-init user account for key-based auth. Sourced from the SSH_RUNNER_ANSIBLE_PUBLIC GitHub secret. A single key string; empty string means no key is injected."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_pm_private_key" {
  description = "SSH private key for authenticating to the Proxmox host as user1. Required by the bpg/proxmox provider for file operations (e.g. uploading hook scripts to the snippets datastore). Sourced from the SSH_RUNNER_PM_PRIVATE GitHub secret."
  type        = string
  sensitive   = true
}