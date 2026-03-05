variable "company_prefix" {
  description = "Company prefix for naming standard (e.g., your company name)"
  type        = string
  default     = "acme"
}

variable "project" {
  description = "Project, workload, or application name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance" {
  description = "Instance number for uniqueness (e.g., 01, 02)"
  type        = string
  default     = "01"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "germanywestcentral"
}

variable "location_abbreviations" {
  description = "Mapping of Azure regions to standard company abbreviations"
  type        = map(string)
  default = {
    "germanywestcentral" = "gwc"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (null for latest)"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS SKU tier (Free or Standard). Standard includes SLA"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be 'Free' or 'Standard'."
  }
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server not publicly accessible)"
  type        = bool
  default     = true
}

variable "automatic_upgrade_channel" {
  description = "Upgrade channel for the cluster (none, patch, rapid, stable, node-image)"
  type        = string
  default     = "patch"
}

variable "node_os_upgrade_channel" {
  description = "Node OS upgrade channel"
  type        = string
  default     = "NodeImage"
}

variable "default_node_pool" {
  description = "Default (system) node pool configuration"
  type = object({
    name                 = optional(string, "system")
    vm_size              = optional(string, "Standard_D4s_v5")
    node_count           = optional(number, 3)
    min_count            = optional(number, 3)
    max_count            = optional(number, 5)
    auto_scaling_enabled = optional(bool, true)
    max_pods             = optional(number, 30)
    os_disk_size_gb      = optional(number, 128)
    os_disk_type         = optional(string, "Managed")
    vnet_subnet_id       = string
    zones                = optional(list(string), ["1", "2", "3"])
  })
}

variable "additional_node_pools" {
  description = "Additional (user) node pools"
  type = list(object({
    name                 = string
    vm_size              = string
    node_count           = number
    min_count            = optional(number)
    max_count            = optional(number)
    auto_scaling_enabled = optional(bool, true)
    max_pods             = optional(number, 30)
    os_disk_size_gb      = optional(number, 128)
    os_type              = optional(string, "Linux")
    vnet_subnet_id       = optional(string)
    zones                = optional(list(string), ["1", "2", "3"])
    mode                 = optional(string, "User")
    node_labels          = optional(map(string), {})
    node_taints          = optional(list(string), [])
  }))
  default = []
}

variable "network_plugin" {
  description = "Network plugin (azure for CNI, kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy (azure, calico, or null)"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service_cidr)"
  type        = string
  default     = "10.100.0.10"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Container Insights"
  type        = string
  default     = ""
}

variable "enable_secret_store_csi" {
  description = "Enable Azure Key Vault Secrets Store CSI Driver"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
