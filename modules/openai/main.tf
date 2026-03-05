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
  base_name     = lower("oai-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")

  # Custom subdomain must be globally unique
  subdomain = var.custom_subdomain_name != "" ? var.custom_subdomain_name : local.base_name
}

resource "azurerm_cognitive_account" "this" {
  name                = local.base_name
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = var.sku_name

  custom_subdomain_name              = local.subdomain
  public_network_access_enabled      = var.public_network_access_enabled
  local_auth_enabled                 = var.local_auth_enabled
  outbound_network_access_restricted = var.outbound_network_access_restricted

  dynamic "network_acls" {
    for_each = var.public_network_access_enabled ? [] : [1]
    content {
      default_action = var.network_acls.default_action
      ip_rules       = var.network_acls.ip_rules
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "this" {
  for_each = { for d in var.deployments : d.name => d }

  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.this.id
  rai_policy_name      = each.value.rai_policy_name

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.scale_type
    capacity = each.value.scale_capacity
  }
}
