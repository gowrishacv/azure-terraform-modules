output "private_endpoint_id" {
  description = "The ID of the Private Endpoint"
  value       = azurerm_private_endpoint.this.id
}

output "private_endpoint_name" {
  description = "The name of the Private Endpoint"
  value       = azurerm_private_endpoint.this.name
}

output "private_ip_addresses" {
  description = "The private IP addresses associated with the private endpoint"
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}

output "network_interface_id" {
  description = "The ID of the network interface associated with the private endpoint"
  value       = azurerm_private_endpoint.this.network_interface[0].id
}

output "custom_dns_configs" {
  description = "Custom DNS configurations for the private endpoint"
  value       = azurerm_private_endpoint.this.custom_dns_configs
}

output "private_dns_zone_group" {
  description = "Private DNS zone group configuration"
  value       = try(azurerm_private_endpoint.this.private_dns_zone_group[0], null)
}

output "private_dns_zone_configs" {
  description = "Private DNS zone configurations (name resolution records)"
  value       = try(azurerm_private_endpoint.this.private_dns_zone_group[0].private_dns_zone_configs, [])
}
