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
  # Naming lookup
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Enterprise Standard Storage Name: lowercase alphanumeric, max 24 chars
  # Example raw: st-acme-project-dev-gwc-01
  raw_name = lower("st${var.company_prefix}${var.project}${var.environment}${local.location_abbr}${var.instance}")

  # Strip hyphens and any other special characters, then truncate to 24 chars
  st_name_clean = replace(local.raw_name, "/[^a-z0-9]/", "")
  st_name       = substr(local.st_name_clean, 0, 24)
}

resource "azurerm_storage_account" "this" {
  name                            = local.st_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.replication_type
  account_kind                    = var.account_kind
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  public_network_access_enabled   = var.public_network_access_enabled
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.shared_access_key_enabled

  blob_properties {
    versioning_enabled = var.enable_versioning

    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_days > 0 ? [1] : []
      content {
        days = var.blob_soft_delete_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_days > 0 ? [1] : []
      content {
        days = var.container_soft_delete_days
      }
    }
  }

  network_rules {
    default_action             = var.network_rules.default_action
    bypass                     = var.network_rules.bypass
    ip_rules                   = var.network_rules.ip_rules
    virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each = { for c in var.containers : c.name => c }

  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = lookup(each.value, "access_type", "private")
}

# -------------------------------------------------------------
# Advanced Threat Protection (Defender for Storage)
# -------------------------------------------------------------
resource "azurerm_advanced_threat_protection" "this" {
  count = var.enable_advanced_threat_protection ? 1 : 0

  target_resource_id = azurerm_storage_account.this.id
  enabled            = true
}

# -------------------------------------------------------------
# Blob Diagnostic Settings (Send Blob Read/Write events to SIEM)
# -------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "blob" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${local.st_name}-blob-diag"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}
