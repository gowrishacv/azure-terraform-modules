terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  # Naming lookup
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Enterprise Standard Key Vault Name: must be between 3-24 characters, alphanumeric and hyphens only
  raw_name = lower("kv-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")

  # Key Vault names can have hyphens, but we must still enforce the 24 char limit
  # trimsuffix prevents names ending with '-' which Azure rejects
  kv_name = trimsuffix(substr(local.raw_name, 0, 24), "-")
}

resource "azurerm_key_vault" "this" {
  name                          = local.kv_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  enable_rbac_authorization     = var.enable_rbac_authorization
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    bypass                     = var.network_acls.bypass
    default_action             = var.network_acls.default_action
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  tags = var.tags
}

# Access policies (only used when RBAC is disabled)
resource "azurerm_key_vault_access_policy" "this" {
  for_each = var.enable_rbac_authorization ? {} : { for policy in var.access_policies : policy.object_id => policy }

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
}

# -------------------------------------------------------------
# Key Vault Audit Diagnostics
# -------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${local.kv_name}-diag"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
