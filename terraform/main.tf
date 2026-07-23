# Upload NAT hook scripts per VM.
# These are placed in Proxmox's snippet storage so the VM hook mechanism can
# reference them. Each script resolves the VM's current IP via the QEMU guest
# agent at runtime (no hardcoded IPs) and installs/removes iptables DNAT rules
# for the configured port forwards.
resource "proxmox_virtual_environment_file" "nat_hook" {
  for_each = {
    for name, vm in var.vms : name => vm
    if length(vm.forwards) > 0
  }

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    data = templatefile("${path.module}/templates/nat-hook.sh.tpl", {
      forwards = each.value.forwards
    })
    file_name = "nat-hook-${each.key}.sh"
    file_mode = "0755"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  node_name = var.target_node
  vm_id     = each.value.vm_id
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
      # Inject the runner's SSH public key for key-based auth (in addition to
      # the password). The bpg/proxmox provider exposes this as `keys` (a
      # list(string)) under user_account. The ssh_public_keys variable is a
      # single string (the SSH_RUNNER_ANSIBLE_PUBLIC GitHub secret); convert it
      # to a one-element list, or an empty list when unset so cloud-init ignores
      # it and password-only behavior is preserved.
      keys = var.ssh_public_keys == "" ? [] : [var.ssh_public_keys]
    }
  }

  # Wire the NAT hook script when forwards are configured for this VM.
  # VMs with no forwards do not produce a hook file resource, so use
  # try() to gracefully fall back to null (no hook script attached).
  hook_script_file_id = try(proxmox_virtual_environment_file.nat_hook[each.key].id, null)

  lifecycle {
    ignore_changes = [
      disk[0].file_id,
    ]
  }
}