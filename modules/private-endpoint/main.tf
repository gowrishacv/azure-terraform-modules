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

  # Naming: pe-{resource-type}-{company}-{project}-{env}-{region}-{instance}
  # Example: pe-kv-acme-platform-prod-gwc-01
  pe_name = lower("pe-${var.resource_type_abbreviation}-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")
}

# -------------------------------------------------------------
# Private Endpoint
# -------------------------------------------------------------
resource "azurerm_private_endpoint" "this" {
  name                = local.pe_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${local.pe_name}-connection"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = var.is_manual_connection
    request_message                = var.is_manual_connection ? var.request_message : null
  }

  # Optional: Private DNS Zone Group for automatic DNS registration
  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "${local.pe_name}-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  # Optional: Custom DNS configuration (alternative to DNS zone group)
  dynamic "ip_configuration" {
    for_each = var.ip_configurations
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  tags = merge(var.tags, {
    resource-type = "private-endpoint"
    target-resource = var.private_connection_resource_id
  })

  lifecycle {
    ignore_changes = [
      tags["created-date"]
    ]
  }
}

# -------------------------------------------------------------
# Diagnostic Settings (if Log Analytics workspace provided)
# -------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${local.pe_name}-diagnostics"
  target_resource_id         = azurerm_private_endpoint.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AllMetrics"
  }
}
