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
  # Naming lookup
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Enterprise Standard Naming
  aks_name = lower("aks-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}-${var.instance}")

  # DNS prefix removes hyphens mapping directly to the aks name construct
  dns_prefix = replace(local.aks_name, "-", "")
}

resource "azurerm_kubernetes_cluster" "this" {
  name                      = local.aks_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = local.dns_prefix
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = var.sku_tier
  private_cluster_enabled   = var.private_cluster_enabled
  automatic_upgrade_channel = var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                 = var.default_node_pool.name
    vm_size              = var.default_node_pool.vm_size
    node_count           = var.default_node_pool.node_count
    min_count            = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.min_count : null
    max_count            = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.max_count : null
    auto_scaling_enabled = var.default_node_pool.auto_scaling_enabled
    max_pods             = var.default_node_pool.max_pods
    os_disk_size_gb      = var.default_node_pool.os_disk_size_gb
    os_disk_type         = var.default_node_pool.os_disk_type
    vnet_subnet_id       = var.default_node_pool.vnet_subnet_id
    zones                = var.default_node_pool.zones

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != "" ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_secret_store_csi ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4]
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }
}

# Additional node pools
resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = { for pool in var.additional_node_pools : pool.name => pool }

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count             = each.value.auto_scaling_enabled ? each.value.max_count : null
  auto_scaling_enabled  = each.value.auto_scaling_enabled
  max_pods              = lookup(each.value, "max_pods", 30)
  os_disk_size_gb       = lookup(each.value, "os_disk_size_gb", 128)
  os_type               = lookup(each.value, "os_type", "Linux")
  vnet_subnet_id        = lookup(each.value, "vnet_subnet_id", null)
  zones                 = lookup(each.value, "zones", ["1", "2", "3"])
  mode                  = lookup(each.value, "mode", "User")
  node_labels           = lookup(each.value, "node_labels", {})
  node_taints           = lookup(each.value, "node_taints", [])

  tags = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}
