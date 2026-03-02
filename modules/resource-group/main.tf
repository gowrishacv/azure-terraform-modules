terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

locals {
  # Look up region abbreviation, fall back to full location name if not found
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Dynamic Standard: rg-acme-project-dev-gwc-01
  rg_name = lower("rg-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location

  tags = merge(var.default_tags, var.extra_tags, {
    environment = var.environment
    project     = var.project
    managed-by  = "terraform"
  })

  lifecycle {
    ignore_changes = [
      tags["created-date"]
    ]
  }
}

# -------------------------------------------------------------
# Enterprise Security: Resource Locks
# -------------------------------------------------------------
resource "azurerm_management_lock" "this" {
  count = var.lock_level != "" ? 1 : 0

  name       = "${local.rg_name}-lock"
  scope      = azurerm_resource_group.this.id
  lock_level = var.lock_level
  notes      = "Enterprise lock applied by Terraform automation."
}

# -------------------------------------------------------------
# Enterprise Security: RBAC Role Assignments
# -------------------------------------------------------------
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_resource_group.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
