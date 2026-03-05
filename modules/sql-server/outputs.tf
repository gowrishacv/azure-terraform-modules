output "sql_server_id" {
  description = "The Microsoft SQL Server ID"
  value       = azurerm_mssql_server.this.id
}

output "sql_server_name" {
  description = "The dynamically generated name of the SQL Server"
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the Azure SQL Server"
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_server_identity" {
  description = "An identity block exporting Principal ID and Tenant ID"
  value       = azurerm_mssql_server.this.identity
}
