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

variable "os_type" {
  description = "OS type for the App Service Plan"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be 'Linux' or 'Windows'."
  }
}

variable "sku_name" {
  description = "SKU for the App Service Plan (B1, S1, P1v3, etc.)"
  type        = string
  default     = "P1v3"
}

variable "always_on" {
  description = "Keep the app always loaded"
  type        = bool
  default     = true
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration (optional)"
  type        = string
  default     = null
}

variable "application_stack" {
  description = "Application runtime stack configuration"
  type        = map(string)
  default     = null
}

variable "app_settings" {
  description = "Application settings (environment variables). Values may contain secrets and will be marked sensitive."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
