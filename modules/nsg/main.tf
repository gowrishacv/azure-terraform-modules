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

  # Enterprise Standard: nsg-acme-project-dev-gwc-01
  nsg_name = lower("nsg-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")

  # Baseline Deny Rules (if enabled)
  baseline_rules = var.add_baseline_deny_rules ? [
    {
      name                                       = "Enterprise-DenyAllInBound"
      priority                                   = 4096
      direction                                  = "Inbound"
      access                                     = "Deny"
      protocol                                   = "*"
      source_port_range                          = "*"
      destination_port_range                     = "*"
      source_address_prefix                      = "*"
      destination_address_prefix                 = "*"
      source_address_prefixes                    = null
      destination_address_prefixes               = null
      source_application_security_group_ids      = null
      destination_application_security_group_ids = null
    },
    {
      name                                       = "Enterprise-DenyAllOutBound"
      priority                                   = 4096
      direction                                  = "Outbound"
      access                                     = "Deny"
      protocol                                   = "*"
      source_port_range                          = "*"
      destination_port_range                     = "*"
      source_address_prefix                      = "*"
      destination_address_prefix                 = "*"
      source_address_prefixes                    = null
      destination_address_prefixes               = null
      source_application_security_group_ids      = null
      destination_application_security_group_ids = null
    }
  ] : []

  # Combine User Custom Rules with Baseline Rules
  all_rules = concat(var.rules, local.baseline_rules)
}

resource "azurerm_network_security_group" "this" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Iterate over combined user and baseline rules
resource "azurerm_network_security_rule" "this" {
  for_each = { for rule in local.all_rules : rule.name => rule }

  name                                       = each.value.name
  priority                                   = each.value.priority
  direction                                  = each.value.direction
  access                                     = each.value.access
  protocol                                   = each.value.protocol
  source_port_range                          = lookup(each.value, "source_port_range", "*")
  destination_port_range                     = lookup(each.value, "destination_port_range", null)
  destination_port_ranges                    = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix                      = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes                    = lookup(each.value, "source_address_prefixes", null)
  source_application_security_group_ids      = lookup(each.value, "source_application_security_group_ids", null)
  destination_address_prefix                 = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes               = lookup(each.value, "destination_address_prefixes", null)
  destination_application_security_group_ids = lookup(each.value, "destination_application_security_group_ids", null)

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

# Associate NSG with subnets (Though enterprise architecture often does this inside the VNet module explicitly)
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = toset(var.subnet_ids)

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this.id
}

# -------------------------------------------------------------
# NSG Diagnostic Settings
# Note: For actual NSG Flow Logs (azurerm_network_watcher_flow_log),
# configure separately via Network Watcher with a storage account.
# -------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${local.nsg_name}-diag"
  target_resource_id         = azurerm_network_security_group.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Export NSG Rule Flow events to SIEM
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
