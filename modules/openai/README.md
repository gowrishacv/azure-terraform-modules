# Azure OpenAI Module

Creates an Azure OpenAI Service account with enterprise security: Entra ID RBAC, network ACLs, managed identity authentication, multi-model deployments, and diagnostic logging.

## Usage

```hcl
module "openai" {
  source = "../../modules/openai"

  company_prefix = "acme"
  project        = "platform"
  environment    = "prod"
  location       = "eastus"

  resource_group_name = module.rg.name
  sku_name            = "S0"

  public_network_access_enabled = false

  deployments = [
    {
      name          = "gpt-4-turbo"
      model_name    = "gpt-4-turbo"
      model_version = "2024-04-09"
      capacity      = 10
    }
  ]

  network_acls = {
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["snet-app"]]
  }

  log_analytics_workspace_id = module.log_analytics.id

  tags = module.rg.tags
}
```

## Design Decisions

- **Entra ID RBAC**: Enforces Azure AD-based access control via roles (Cognitive Services User, Contributor)
- **Managed Identity support**: Applications authenticate without storing credentials
- **Public access disabled**: Restricts traffic to approved VNet subnets only
- **Multi-model deployments**: Supports simultaneous deployment of different LLM versions (GPT-4, GPT-3.5, etc.)
- **Network ACLs**: Default-deny firewall with explicit allowlisting of trusted networks
- **Diagnostic logging**: Tracks API usage, latency, and error patterns to Log Analytics
