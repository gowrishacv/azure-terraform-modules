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
  # Naming Convention Helper
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Enterprise Standard: vnet-acme-project-dev-gwc-01
  vnet_name = lower("vnet-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  # Conditionally attach a DDoS Protection Plan if the string is not empty
  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != "" ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = var.tags
}

# -------------------------------------------------------------
# Subnets
# -------------------------------------------------------------
resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                                          = each.value.name
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = lookup(each.value, "service_endpoints", null)
  private_endpoint_network_policies             = lookup(each.value, "private_endpoint_network_policies", "Enabled")
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.service_delegation_actions
      }
    }
  }
}

# -------------------------------------------------------------
# Security & Routing Subnet Attachments
# -------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "network_security_group_id", null) != null
  }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value.network_security_group_id
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "route_table_id", null) != null
  }

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = each.value.route_table_id
}


# -------------------------------------------------------------
# Peering
# -------------------------------------------------------------
resource "azurerm_virtual_network_peering" "this" {
  for_each = { for peer in var.peerings : peer.name => peer }

  name                         = each.value.name
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = each.value.remote_vnet_id
  allow_virtual_network_access = lookup(each.value, "allow_vnet_access", true)
  allow_forwarded_traffic      = lookup(each.value, "allow_forwarded_traffic", false)
  allow_gateway_transit        = lookup(each.value, "allow_gateway_transit", false)
  use_remote_gateways          = lookup(each.value, "use_remote_gateways", false)
}


# -------------------------------------------------------------
# VNet Diagnostic Settings (Logs and Metrics)
# -------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${local.vnet_name}-diag"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  enabled_log {
    category = "AllMetrics"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
