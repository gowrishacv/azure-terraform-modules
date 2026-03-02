variable "company_prefix" {
  description = "Company prefix for naming standard (e.g., your company name)"
  type        = string
  default     = "acme"
}

variable "project" {
  description = "Project, workload, or application name"
  type        = string
}

variable "instance" {
  description = "Instance number for uniqueness (e.g., 01, 02)"
  type        = string
  default     = "01"
}

variable "location" {
  description = "Azure region for the resource group"
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

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "lock_level" {
  description = "Management lock level for the RG. Options: '', 'CanNotDelete', 'ReadOnly'."
  type        = string
  default     = "" # Empty means no lock
  validation {
    condition     = contains(["", "CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "Lock level must be '', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "role_assignments" {
  description = "Map of RBAC roles to assign automatically at the RG scope."
  type = map(object({
    role_definition_name = string
    principal_id         = string
  }))
  default = {}
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    owner       = "cloud-platform-team"
    cost-center = "infrastructure"
  }
}

variable "extra_tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
