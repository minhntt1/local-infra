# Import existing VMs into Terraform state.
#
# These VMs were originally created by Terraform, but their state was lost
# (local state on the self-hosted runner). On the next apply Terraform tried
# to re-create them via clone and failed with:
#   "error cloning VM: the requested resource already exists ... config file already exists"
# because VM 200 (prod) and VM 201 (dev) already exist on the Proxmox node.
#
# Importing them back into state lets Terraform manage them in place instead
# of attempting to recreate them. Import blocks are idempotent: once a
# resource is already present in state, Terraform skips the import on later
# runs, so leaving these blocks in the configuration is safe.
#
# Import ID format for bpg/proxmox is "<node>/<vm_id>".

import {
  to = proxmox_virtual_environment_vm.vm["prod"]
  id = "${var.target_node}/${var.vms["prod"].vm_id}"
}

import {
  to = proxmox_virtual_environment_vm.vm["dev"]
  id = "${var.target_node}/${var.vms["dev"].vm_id}"
}
