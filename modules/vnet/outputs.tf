output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "VNet address space (list of CIDRs)"
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet name to address prefixes"
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes }
}

output "subnet_nsg_associations" {
  description = "Map of subnet names that have an NSG successfully associated"
  value = {
    for k, v in azurerm_subnet_network_security_group_association.this :
    k => v.network_security_group_id
  }
}

output "subnet_route_table_associations" {
  description = "Map of subnet names that have a Route Table successfully associated"
  value = {
    for k, v in azurerm_subnet_route_table_association.this :
    k => v.route_table_id
  }
}
