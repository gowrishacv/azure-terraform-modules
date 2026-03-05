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

  # Enterprise Standard Naming
  app_name = lower("app-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")
  asp_name = lower("asp-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")
}

resource "azurerm_service_plan" "this" {
  name                = local.asp_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_linux_web_app" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                      = local.app_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.this.id
  https_only                = true
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    always_on           = var.always_on
    http2_enabled       = true

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        docker_image_name   = lookup(application_stack.value, "docker_image_name", null)
        dotnet_version      = lookup(application_stack.value, "dotnet_version", null)
        python_version      = lookup(application_stack.value, "python_version", null)
        node_version        = lookup(application_stack.value, "node_version", null)
        java_version        = lookup(application_stack.value, "java_version", null)
        java_server         = lookup(application_stack.value, "java_server", null)
        java_server_version = lookup(application_stack.value, "java_server_version", null)
      }
    }
  }

  app_settings = merge(var.app_settings, {
    WEBSITE_RUN_FROM_PACKAGE = "1"
  })

  tags = var.tags
}

resource "azurerm_windows_web_app" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                      = local.app_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.this.id
  https_only                = true
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    always_on           = var.always_on
    http2_enabled       = true
  }

  app_settings = var.app_settings

  tags = var.tags
}

# -------------------------------------------------------------
# App Service Diagnostic Settings
# -------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "linux" {
  count = var.log_analytics_workspace_id != "" && var.os_type == "Linux" ? 1 : 0

  name                       = "${local.app_name}-diag"
  target_resource_id         = azurerm_linux_web_app.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "windows" {
  count = var.log_analytics_workspace_id != "" && var.os_type == "Windows" ? 1 : 0

  name                       = "${local.app_name}-diag"
  target_resource_id         = azurerm_windows_web_app.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
