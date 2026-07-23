terraform {
  required_version = ">= 1.5"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  # endpoint  = var.pm_api_url
  # api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  # insecure  = true

  ssh {
    agent       = false
    username    = "root"
    private_key = var.ssh_pm_private_key
  }
}
