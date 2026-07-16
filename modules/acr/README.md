# Container Registry (ACR) Module

Creates an Azure Container Registry with enterprise security: content trust, disabled admin access, private endpoint support, geo-replication, and diagnostic logging.

## Usage

```hcl
module "acr" {
  source = "../../modules/acr"

  company_prefix = "acme"
  project        = "platform"
  environment    = "prod"
  location       = "germanywestcentral"

  resource_group_name = module.rg.name
  sku                 = "Premium"
  admin_enabled       = false

  public_network_access_enabled = false
  
  georeplications = [
    {
      location                = "westeurope"
      zone_redundancy_enabled = true
    }
  ]

  log_analytics_workspace_id = module.log_analytics.id

  tags = module.rg.tags
}
```

## Design Decisions

- **Premium SKU default**: Required for content trust, geo-replication, and network rules
- **Admin disabled by default**: Enforces Entra ID RBAC-only authentication for better security
- **Public access disabled**: Forces private connectivity via private endpoints or approved IP ranges
- **Content trust enabled**: Prevents unsigned image deployments (Premium SKU only)
- **Geo-replication support**: Built-in multi-region availability for Premium tier
- **Diagnostic logging**: Optional but recommended for audit trails and troubleshooting
