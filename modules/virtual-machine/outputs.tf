output "vm_ids" {
  description = "List of Virtual Machine IDs created by this module"
  value = var.os_type == "Linux" ? [
    for vm in azurerm_linux_virtual_machine.linux : vm.id
    ] : [
    for vm in azurerm_windows_virtual_machine.windows : vm.id
  ]
}

output "vm_names" {
  description = "List of Virtual Machine Names created by this module"
  value = var.os_type == "Linux" ? [
    for vm in azurerm_linux_virtual_machine.linux : vm.name
    ] : [
    for vm in azurerm_windows_virtual_machine.windows : vm.name
  ]
}

output "network_interface_ids" {
  description = "List of Network Interface IDs created and attached to the VMs"
  value = [
    for nic in azurerm_network_interface.this : nic.id
  ]
}

output "vm_private_ips" {
  description = "List of Private IP Addresses assigned to the VMs"
  value = [
    for nic in azurerm_network_interface.this : nic.private_ip_address
  ]
}

output "system_assigned_principal_ids" {
  description = "List of the System Assigned Managed Identity Principal IDs for the VMs (useful for RBAC key vault grants)"
  value = var.os_type == "Linux" ? [
    for vm in azurerm_linux_virtual_machine.linux : vm.identity[0].principal_id
    ] : [
    for vm in azurerm_windows_virtual_machine.windows : vm.identity[0].principal_id
  ]
}
