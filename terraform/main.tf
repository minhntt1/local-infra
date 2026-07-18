resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  node_name = var.target_node
  vm_id     = each.key == "prod" ? 200 : 201
  name      = each.key
  started   = true
  onboot    = var.vm_defaults.onboot
  tags      = [each.key, "terraform"]

  clone {
    vm_id = 9999
    full  = true
  }

  agent {
    enabled = var.vm_defaults.agent
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk_gb
    ssd          = true
  }

  network_device {
    bridge = var.vm_defaults.bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = var.vm_defaults.ciuser
      password = var.vm_defaults.cipassword
    }
  }

  lifecycle {
    ignore_changes = [
      disk[0].file_id,
    ]
  }
}