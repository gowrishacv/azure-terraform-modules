# Log Analytics Module

Creates an Azure Log Analytics Workspace with secure defaults: retention policies, private ingestion/query, daily quota controls, and enterprise naming conventions.

## Usage

```hcl
module "log_analytics" {
  source = "../../modules/log-analytics"

  company_prefix = "acme"
  project        = "platform"
  environment    = "prod"
  location       = "germanywestcentral"

  resource_group_name = module.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  internet_ingestion_enabled = false
  internet_query_enabled     = false
  daily_quota_gb             = 10

  tags = module.rg.tags
}
```

## Design Decisions

- **90-day retention default**: Aligns with CIS Azure Foundations Benchmark (section 5.1.5)
- **Private ingestion/query**: Defaults to disabled (`internet_ingestion_enabled = false`, `internet_query_enabled = false`) for compliance-sensitive environments
- **Daily quota controls**: Prevents runaway logs from consuming unexpected costs
- **PerGB2018 SKU**: Standard production tier with predictable pricing based on data ingested
- **Diagnostic hub**: Central location for all Azure Monitor logs from dependent resources
