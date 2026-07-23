# Upload NAT hook scripts per VM and register them via the Proxmox API.
# Uses local-exec with curl + the API token (same auth as the provider) instead
# of proxmox_virtual_environment_file, which requires SSH that the runner doesn't have.
resource "null_resource" "nat_hook" {
  for_each = {
    for name, vm in var.vms : name => vm
    if length(vm.forwards) > 0
  }

  triggers = {
    template_hash = sha256(templatefile("${path.module}/templates/nat-hook.sh.tpl", {
      forwards = each.value.forwards
    }))
    vm_id = each.value.vm_id
  }

  provisioner "local-exec" {
    command = <<EOC
      SCRIPT_NAME="nat-hook-${each.key}.sh"
      SCRIPT_PATH="/var/lib/vz/snippets/${SCRIPT_NAME}"

      # Write the rendered hook script to a temp file
      cat > /tmp/${SCRIPT_NAME} << 'SCRIPTEOF'
${templatefile("${path.module}/templates/nat-hook.sh.tpl", {
  forwards = each.value.forwards
})}
SCRIPTEOF

      # Upload the snippet file to the Proxmox host's local storage via the API.
      # The API endpoint for file upload to a storage is:
      # POST /nodes/{node}/storage/{storage}/upload
      # with content-type= snippets and the file as multipart form data.
      curl -sk \
        --header "Authorization: Proxmox ${var.pm_api_token_id}=${var.pm_api_token_secret}" \
        -X POST \
        -F "content=snippets" \
        -F "filename=@/tmp/${SCRIPT_NAME}" \
        "https://$(ip route show default | awk '{print $3}'):8006/api2/json/nodes/${var.target_node}/storage/local/upload"

      # Set the hook script on the VM via the API.
      # PUT /nodes/{node}/qemu/{vmid}/config
      curl -sk \
        --header "Authorization: Proxmox ${var.pm_api_token_id}=${var.pm_api_token_secret}" \
        -X PUT \
        -d "hookscript=local:snippets/${SCRIPT_NAME}" \
        "https://$(ip route show default | awk '{print $3}'):8006/api2/json/nodes/${var.target_node}/qemu/${each.value.vm_id}/config"

      rm -f /tmp/${SCRIPT_NAME}
    EOC
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOC
      SCRIPT_NAME="nat-hook-${each.key}.sh"
      PROXMOX_IP=$(ip route show default | awk '{print $3}')

      # Remove the hook script reference from the VM
      curl -sk \
        --header "Authorization: Proxmox ${var.pm_api_token_id}=${var.pm_api_token_secret}" \
        -X PUT \
        -d "delete=hookscript" \
        "https://${PROXMOX_IP}:8006/api2/json/nodes/${var.target_node}/qemu/${each.value.vm_id}/config" 2>/dev/null || true

      # Delete the snippet file from the storage
      curl -sk \
        --header "Authorization: Proxmox ${var.pm_api_token_id}=${var.pm_api_token_secret}" \
        -X DELETE \
        "https://${PROXMOX_IP}:8006/api2/json/nodes/${var.target_node}/storage/local/content/local:snippets/${SCRIPT_NAME}" 2>/dev/null || true
    EOC
  }

  depends_on = [proxmox_virtual_environment_vm.vm]
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

  lifecycle {
    ignore_changes = [
      disk[0].file_id,
    ]
  }
}