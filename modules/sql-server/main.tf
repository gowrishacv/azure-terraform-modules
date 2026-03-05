terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

locals {
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Enterprise Standard Naming
  sql_name = lower("sql-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")
}

# Usually you need an Entra ID group or SP to act as the SQL Admin
data "azuread_group" "sql_admin" {
  count        = var.azuread_admin_group_name != "" ? 1 : 0
  display_name = var.azuread_admin_group_name
}

resource "azurerm_mssql_server" "this" {
  name                = local.sql_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.sql_version

  # Avoid using SQL Authentication in Enterprise if possible
  administrator_login          = var.sql_admin_username != "" ? var.sql_admin_username : null
  administrator_login_password = var.sql_admin_password != "" ? var.sql_admin_password : null

  minimum_tls_version           = "1.2"
  public_network_access_enabled = var.public_network_access_enabled

  identity {
    type = "SystemAssigned"
  }

  # Required Entra ID (Azure AD) Admin Block
  dynamic "azuread_administrator" {
    for_each = var.azuread_admin_group_name != "" ? [1] : []
    content {
      login_username              = var.azuread_admin_group_name
      object_id                   = data.azuread_group.sql_admin[0].object_id
      azuread_authentication_only = var.azuread_authentication_only
    }
  }

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "this" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# -------------------------------------------------------------
# Microsoft Defender for SQL
# -------------------------------------------------------------
resource "azurerm_mssql_server_security_alert_policy" "this" {
  resource_group_name  = var.resource_group_name
  server_name          = azurerm_mssql_server.this.name
  state                = "Enabled"
  disabled_alerts      = []
  email_account_admins = var.email_security_alerts_to_admins
  email_addresses      = var.security_alert_emails
  retention_days       = var.alert_retention_days
}

resource "azurerm_mssql_server_vulnerability_assessment" "this" {
  count = var.vulnerability_assessment_storage_container_path != "" ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.this.id
  storage_container_path          = var.vulnerability_assessment_storage_container_path

  # For modern deployments, it's better to use Managed Identities instead of SAS tokens
  # Assuming the SQL Server's SystemAssigned identity has Blob Data Contributor on the storage account
}

# -------------------------------------------------------------
# Diagnostic Auditing
# -------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${local.sql_name}-master-diag"
  target_resource_id         = "${azurerm_mssql_server.this.id}/databases/master"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
