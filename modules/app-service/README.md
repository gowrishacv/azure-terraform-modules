# App Service Module

Creates an Azure App Service (Linux or Windows) with managed identity, HTTPS enforcement, VNet integration, and secure defaults.

## Usage

```hcl
module "app_service" {
  source = "../../modules/app-service"

  name              = "app-api-dev-gwc"
  service_plan_name = "asp-api-dev-gwc"
  location          = module.rg.location
  resource_group_name = module.rg.name
  os_type           = "Linux"
  sku_name          = "P1v3"

  vnet_integration_subnet_id = module.vnet.subnet_ids["snet-appservice"]

  application_stack = {
    dotnet_version = "8.0"
  }

  app_settings = {
    ASPNETCORE_ENVIRONMENT = "Development"
    KeyVaultUri            = module.key_vault.vault_uri
  }

  tags = module.rg.tags
}
```

## Design Decisions

- **System-assigned managed identity**: Created automatically. Use it to authenticate to Key Vault, Storage, SQL without secrets
- **HTTPS only + TLS 1.2**: Enforced at the infrastructure level, not the application level
- **FTPS disabled**: No FTP deployments. Use CI/CD or zip deploy instead
- **VNet integration**: Optional but recommended for private backend connectivity
- **Linux and Windows support**: Uses conditional resources based on `os_type`
