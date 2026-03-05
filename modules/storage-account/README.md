# Storage Account Module

Creates an Azure Storage Account with security hardening: TLS 1.2, HTTPS-only, no public blob access, versioning, soft delete, and network restrictions.

## Usage

```hcl
module "storage" {
  source = "../../modules/storage-account"

  name                = "stplatformdevgwc"
  location            = module.rg.location
  resource_group_name = module.rg.name
  replication_type    = "ZRS"

  containers = [
    { name = "artifacts" },
    { name = "backups" }
  ]

  network_rules = {
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["snet-aks"]]
  }

  tags = module.rg.tags
}
```

## Design Decisions

- **Shared key disabled by default**: Forces Entra ID (Azure AD) authentication. More secure than shared keys
- **Public access blocked**: `allow_nested_items_to_be_public = false` prevents accidental blob exposure
- **ZRS default**: Zone-redundant storage for production resilience without the cost of GRS
- **Versioning + soft delete**: Protection against accidental deletion and overwrites
