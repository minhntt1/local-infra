resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  node_name = var.target_node
  vm_id     = each.key == "prod" ? 200 : 201
  name      = each.key
  # Desired power state is driven by var.vm_power_state (keyed by VM name).
  # "started" => power on and auto-start on host boot; "stopped" => power off
  # and do not auto-start. Changing this only triggers a graceful shutdown or
  # start — it never destroys the VM, so disk/network/config are preserved.
  started = var.vm_power_state[each.key] == "started"
  # reboot_after_update defaults to true in the bpg/proxmox provider. This means
  # an in-place update (e.g. state reconciliation after an import, or a config
  # change that requires it) will shut down and restart the VM to apply. This is
  # expected behavior — no destroy occurs. Left at the default intentionally so
  # that real config changes (CPU/memory/etc.) take effect on the running VM.
  on_boot = var.vm_power_state[each.key] == "started"
  tags    = [each.key, "terraform"]

  # The clone block is only relevant when Terraform CREATES a new VM from the
  # template. For VMs that already exist (e.g. imported via imports.tf), the
  # clone arguments (vm_id/full) force a destroy-and-recreate, which is wrong.
  # Gate it behind var.create_vms so it is omitted for existing VMs and only
  # applied when provisioning fresh VMs.
  dynamic "clone" {
    for_each = var.create_vms ? [1] : []
    content {
      vm_id = 9999
      full  = true
    }
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