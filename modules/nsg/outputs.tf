output "nsg_id" {
  description = "NSG resource ID"
  value       = azurerm_network_security_group.this.id
}

output "nsg_name" {
  description = "NSG name"
  value       = azurerm_network_security_group.this.name
}

output "rules" {
  description = "Map of all rules created inside the NSG (including baseline rules if enabled)"
  value       = azurerm_network_security_rule.this
}
