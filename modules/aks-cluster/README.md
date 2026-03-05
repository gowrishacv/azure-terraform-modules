# AKS Cluster Module

Creates an Azure Kubernetes Service cluster with production defaults: private API server, Azure CNI, RBAC, workload identity, auto-scaling, maintenance windows, and optional monitoring.

## Usage

```hcl
module "aks" {
  source = "../../modules/aks-cluster"

  name                = "aks-platform-dev-gwc"
  location            = module.rg.location
  resource_group_name = module.rg.name
  dns_prefix          = "aks-platform-dev"

  kubernetes_version      = "1.29"
  private_cluster_enabled = true
  sku_tier                = "Standard"

  default_node_pool = {
    vm_size        = "Standard_D4s_v5"
    node_count     = 3
    min_count      = 3
    max_count      = 10
    vnet_subnet_id = module.vnet.subnet_ids["snet-aks"]
  }

  additional_node_pools = [
    {
      name       = "workload"
      vm_size    = "Standard_D8s_v5"
      node_count = 2
      min_count  = 2
      max_count  = 20
      node_labels = {
        "workload-type" = "application"
      }
    }
  ]

  log_analytics_workspace_id = module.log_analytics.id
  enable_secret_store_csi    = true

  tags = module.rg.tags
}
```

## Design Decisions

- **Private cluster by default**: API server is not exposed to the internet. Access via VPN, ExpressRoute, or private endpoint
- **Azure CNI**: Pods get real VNet IPs. Required for proper NSG enforcement and service endpoint access
- **Azure network policy**: Native integration with Azure networking. Use Calico if you need egress policies
- **Workload identity enabled**: OIDC issuer + federated credentials replace pod identity (which is deprecated)
- **System-assigned identity**: Simplifies RBAC. The cluster identity gets Network Contributor on the subnet automatically
- **Lifecycle ignores**: `node_count` is ignored because the autoscaler manages it. `kubernetes_version` is ignored to prevent drift when auto-upgrade is enabled
- **Maintenance window**: Sunday 00:00-05:00 UTC. Prevents surprise upgrades during business hours
- **Secrets Store CSI**: Mounts Key Vault secrets directly into pods without application-level SDK changes
- **Standard SKU tier**: Includes financially-backed SLA. Use Free for non-production only
