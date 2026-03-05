output "openai_id" {
  description = "The ID of the Cognitive Services Azure OpenAI Account"
  value       = azurerm_cognitive_account.this.id
}

output "openai_name" {
  description = "The Name of the Azure OpenAI Account"
  value       = azurerm_cognitive_account.this.name
}

output "openai_endpoint" {
  description = "The Endpoint URL for the Azure OpenAI Account"
  value       = azurerm_cognitive_account.this.endpoint
}

output "primary_access_key" {
  description = "The primary access key for the Azure OpenAI Account (sensitive)"
  value       = azurerm_cognitive_account.this.primary_access_key
  sensitive   = true
}

output "deployments" {
  description = "Map of all model deployments created on this Azure OpenAI account"
  value = {
    for k, v in azurerm_cognitive_deployment.this : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "principal_id" {
  description = "The Principal ID for the System Assigned Managed Identity"
  value       = try(azurerm_cognitive_account.this.identity[0].principal_id, "")
}
