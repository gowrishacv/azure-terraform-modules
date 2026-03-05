output "aks_id" {
  description = "AKS Cluster ID"
  value       = azurerm_kubernetes_cluster.this.id
}

output "aks_name" {
  description = "AKS Cluster dynamically generated name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "node_resource_group" {
  description = "Auto-generated Resource Group containing AKS nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kube_config_raw" {
  description = "Raw Kubernetes config to be used by kubectl and other clients (sensitive)"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL that is associated with the cluster"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}
