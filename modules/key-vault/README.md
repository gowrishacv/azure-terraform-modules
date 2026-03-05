# Key Vault Module

Creates an Azure Key Vault with secure defaults: RBAC authorization, purge protection, network restrictions, and optional diagnostic logging.

## Usage

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                = "kv-platform-dev-gwc"
  location            = module.rg.location
  resource_group_name = module.rg.name

  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  public_network_access_enabled = false

  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["snet-aks"]]
  }

  log_analytics_workspace_id = module.log_analytics.id

  tags = module.rg.tags
}
```

## Design Decisions

- **RBAC over access policies**: Defaults to `enable_rbac_authorization = true`. Access policies are legacy and harder to manage at scale
- **Purge protection on**: Prevents permanent deletion. Critical for production workloads with encryption keys
- **Public access off**: Defaults to private. Use network ACLs or private endpoints for access
- **Diagnostic logging**: Optional but strongly recommended. Sends AuditEvent logs to Log Analytics
