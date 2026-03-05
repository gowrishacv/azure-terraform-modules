output "storage_account_id" {
  description = "Storage Account ID"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Storage Account dynamically generated name"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key (sensitive)"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "container_ids" {
  description = "Map of container name to container ID"
  value       = { for k, v in azurerm_storage_container.this : k => v.id }
}
