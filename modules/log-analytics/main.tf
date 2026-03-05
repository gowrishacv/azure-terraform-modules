terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
  }
}

locals {
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Enterprise Standard Naming
  law_name = lower("log-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.law_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  daily_quota_gb = var.daily_quota_gb

  # Useful for locking down older logs
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags = var.tags
}
