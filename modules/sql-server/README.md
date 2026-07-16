# SQL Server Module

Creates an Azure SQL Server with enterprise security: Entra ID-only authentication, identity blocks, TLS 1.2 enforcement, firewall validation, Defender for SQL, and audit logging.

## Usage

```hcl
module "sql_server" {
  source = "../../modules/sql-server"

  company_prefix = "acme"
  project        = "platform"
  environment    = "prod"
  location       = "germanywestcentral"

  resource_group_name         = module.rg.name
  azuread_admin_group_name    = "SQL Admins"
  public_network_access_enabled = false

  enable_defender_for_sql  = true
  vulnerability_assessment_email = ["security@company.com"]

  log_analytics_workspace_id = module.log_analytics.id

  tags = module.rg.tags
}
```

## Design Decisions

- **Entra ID-only authentication**: Disables SQL Authentication by default; enforces Azure AD identities for all access
- **System-Assigned Managed Identity**: Enables keyless authentication and secrets management
- **TLS 1.2+**: Minimum enforced for all connections; disables weaker protocols
- **Public access disabled**: Database is only accessible via private endpoints or approved networks
- **Defender for SQL enabled**: Real-time threat detection and vulnerability assessments
- **Audit logging**: Tracks all administrative and access events to Log Analytics
- **Microsoft Entra ID admin required**: Use directory groups instead of individual accounts for better governance
