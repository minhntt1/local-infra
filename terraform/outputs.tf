output "vm_info" {
  description = "Information about created VMs"
  value = {
    for name, vm in proxmox_virtual_environment_vm.vm : name => {
      vm_id   = vm.vm_id
      name    = vm.name
      node    = vm.node_name
      ipv4    = vm.ipv4_addresses
      mac     = vm.mac_addresses
    }
  }
}