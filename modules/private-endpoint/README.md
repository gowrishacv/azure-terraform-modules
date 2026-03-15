# Azure Private Endpoint Module

Enterprise-grade Terraform module for creating Azure Private Endpoints with automatic DNS integration and diagnostic logging.

## Features

- ✅ **Private connectivity** to Azure PaaS services (Key Vault, Storage, SQL, ACR, etc.)
- ✅ **Automatic DNS registration** via Private DNS Zone Groups
- ✅ **Manual approval workflows** for cross-subscription connections
- ✅ **Diagnostic logging** to Log Analytics
- ✅ **Enterprise naming convention** (`pe-{type}-{company}-{project}-{env}-{region}-{instance}`)
- ✅ **Custom IP configurations** for advanced networking scenarios

## Security Posture

- **Network isolation**: Eliminates public internet exposure for PaaS services
- **CIS compliance**: Aligns with CIS Azure Foundations Benchmark (Private Endpoints for Storage, Key Vault, SQL)
- **Audit logging**: Diagnostic settings send connection events to Log Analytics
- **Zero trust architecture**: Private connectivity without service endpoints or firewall rules

---

## Usage

### Basic Example: Key Vault Private Endpoint

```hcl
module "pe_keyvault" {
  source = "./modules/private-endpoint"

  project                        = "platform"
  environment                    = "prod"
  location                       = "germanywestcentral"
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]

  resource_type_abbreviation     = "kv"
  private_connection_resource_id = module.key_vault.vault_id
  subresource_names              = ["vault"]

  private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]

  tags = local.default_tags
}
# Creates: pe-kv-acme-platform-prod-gwc-01
```

### Storage Account Private Endpoint (Multiple Subresources)

```hcl
module "pe_storage_blob" {
  source = "./modules/private-endpoint"

  project                        = "platform"
  environment                    = "prod"
  location                       = module.rg.location
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]

  resource_type_abbreviation     = "st"
  private_connection_resource_id = module.storage.storage_account_id
  subresource_names              = ["blob"]  # Can also be: ["file", "table", "queue", "dfs"]

  private_dns_zone_ids           = [azurerm_private_dns_zone.blob.id]
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = local.default_tags
}
```

### SQL Server Private Endpoint

```hcl
module "pe_sql" {
  source = "./modules/private-endpoint"

  project                        = "platform"
  environment                    = "prod"
  location                       = module.rg.location
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]

  resource_type_abbreviation     = "sql"
  private_connection_resource_id = module.sql_server.sql_server_id
  subresource_names              = ["sqlServer"]

  private_dns_zone_ids           = [azurerm_private_dns_zone.sql.id]

  tags = local.default_tags
}
```

### Azure Container Registry (ACR)

```hcl
module "pe_acr" {
  source = "./modules/private-endpoint"

  project                        = "platform"
  environment                    = "prod"
  location                       = module.rg.location
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]

  resource_type_abbreviation     = "acr"
  private_connection_resource_id = module.acr.acr_id
  subresource_names              = ["registry"]

  private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]

  tags = local.default_tags
}
```

### Manual Approval (Cross-Subscription Connection)

```hcl
module "pe_external_storage" {
  source = "./modules/private-endpoint"

  project                        = "platform"
  environment                    = "prod"
  location                       = module.rg.location
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]

  resource_type_abbreviation     = "st"
  private_connection_resource_id = "/subscriptions/xxxx-yyyy/resourceGroups/external-rg/providers/Microsoft.Storage/storageAccounts/externalstorage"
  subresource_names              = ["blob"]

  is_manual_connection = true
  request_message      = "Private endpoint for cross-subscription blob storage access"

  tags = local.default_tags
}
```

---

## Subresource Names Reference

| Azure Service | Subresource Names |
|---------------|------------------|
| **Key Vault** | `vault` |
| **Storage Account** | `blob`, `file`, `table`, `queue`, `dfs` (Data Lake), `web` |
| **SQL Server** | `sqlServer` |
| **SQL Managed Instance** | `managedInstance` |
| **Cosmos DB** | `Sql`, `MongoDB`, `Cassandra`, `Gremlin`, `Table` |
| **Azure Container Registry** | `registry` |
| **Azure OpenAI** | `account` |
| **AKS (API Server)** | `management` |
| **App Service** | `sites` |
| **Azure Functions** | `sites` |
| **Service Bus** | `namespace` |
| **Event Hub** | `namespace` |
| **Redis Cache** | `redisCache` |
| **API Management** | `Gateway` |
| **Machine Learning** | `amlworkspace` |

Full reference: [Microsoft Docs - Private Link Resource Types](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource)

---

## Private DNS Zone Setup

For automatic name resolution, create Private DNS Zones and link them to your VNet:

```hcl
# Example: Key Vault Private DNS Zone
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.rg.name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "keyvault-vnet-link"
  resource_group_name   = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = module.vnet.vnet_id
  registration_enabled  = false
  tags                  = local.default_tags
}
```

### Common Private DNS Zone Names

| Service | Private DNS Zone Name |
|---------|----------------------|
| Key Vault | `privatelink.vaultcore.azure.net` |
| Storage Blob | `privatelink.blob.core.windows.net` |
| Storage File | `privatelink.file.core.windows.net` |
| Storage Table | `privatelink.table.core.windows.net` |
| Storage Queue | `privatelink.queue.core.windows.net` |
| SQL Server | `privatelink.database.windows.net` |
| ACR | `privatelink.azurecr.io` |
| Azure OpenAI | `privatelink.openai.azure.com` |
| AKS | `privatelink.{region}.azmk8s.io` |
| App Service | `privatelink.azurewebsites.net` |
| Service Bus | `privatelink.servicebus.windows.net` |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `company_prefix` | Company prefix for naming | `string` | `"acme"` | no |
| `project` | Project name | `string` | n/a | **yes** |
| `environment` | Environment (dev/staging/prod) | `string` | n/a | **yes** |
| `instance` | Instance number | `string` | `"01"` | no |
| `location` | Azure region | `string` | `"germanywestcentral"` | no |
| `resource_group_name` | Resource group name | `string` | n/a | **yes** |
| `subnet_id` | Subnet ID for private endpoint | `string` | n/a | **yes** |
| `resource_type_abbreviation` | Resource type (kv, st, sql, acr, etc.) | `string` | n/a | **yes** |
| `private_connection_resource_id` | Target resource ID | `string` | n/a | **yes** |
| `subresource_names` | Subresource names (e.g., `["vault"]`) | `list(string)` | n/a | **yes** |
| `is_manual_connection` | Require manual approval | `bool` | `false` | no |
| `request_message` | Approval request message | `string` | `"Please approve..."` | no |
| `private_dns_zone_ids` | Private DNS zone IDs | `list(string)` | `[]` | no |
| `ip_configurations` | Custom IP configurations | `list(object)` | `[]` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID | `string` | `""` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| `private_endpoint_id` | Private endpoint resource ID |
| `private_endpoint_name` | Private endpoint name |
| `private_ip_addresses` | Private IP address(es) |
| `network_interface_id` | Network interface ID |
| `custom_dns_configs` | Custom DNS configurations |
| `private_dns_zone_group` | DNS zone group configuration |
| `private_dns_zone_configs` | DNS zone records |

---

## Complete Example with DNS Setup

See [`examples/private-endpoint-with-dns/`](../../examples/private-endpoint-with-dns/) for a full deployment including:
- Resource Group
- Virtual Network with dedicated subnet
- Private DNS Zones
- Key Vault with private endpoint
- Storage Account with private endpoint (blob + file)

---

## Testing

Validate private connectivity after deployment:

```bash
# From a VM in the same VNet:
nslookup mykv-acme-platform-prod-gwc-01.vault.azure.net
# Should resolve to private IP (10.x.x.x)

# Test connection
curl -I https://mykv-acme-platform-prod-gwc-01.vault.azure.net
```

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.75 |

---

## License

MIT License. See [LICENSE](../../LICENSE) for details.
