output "acr_id" {
  description = "ACR resource ID"
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "ACR dynamically generated name"
  value       = azurerm_container_registry.this.name
}

output "acr_login_server" {
  description = "The URL that can be used to log into the container registry"
  value       = azurerm_container_registry.this.login_server
}

output "acr_admin_username" {
  description = "The Username associated with the Container Registry Admin account"
  value       = azurerm_container_registry.this.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "The Password associated with the Container Registry Admin account"
  value       = azurerm_container_registry.this.admin_password
  sensitive   = true
}
