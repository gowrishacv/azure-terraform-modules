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

variable "sku" {
  description = "Specifies the SKU of the Log Analytics Workspace. Possible values are Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, and PerGB2018."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "The workspace data retention in days. Range between 30 and 730. CIS recommends >= 90 days."
  type        = number
  default     = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "Retention MUST be between 30 and 730 days."
  }
}

variable "daily_quota_gb" {
  description = "The workspace daily quota for ingestion in GB. Defaults to -1 (unlimited)."
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Should the Log Analytics Workspace support ingestion over the Public Internet? Set to false for private-only ingestion."
  type        = bool
  default     = false
}

variable "internet_query_enabled" {
  description = "Should the Log Analytics Workspace support querying over the Public Internet? Set to false for private-only access."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
