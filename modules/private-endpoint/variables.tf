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
  description = "Name of the resource group where the private endpoint will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the private endpoint will be placed"
  type        = string
}

variable "resource_type_abbreviation" {
  description = "Abbreviation for the target resource type (e.g., 'kv' for Key Vault, 'st' for Storage, 'sql' for SQL)"
  type        = string

  validation {
    condition = contains([
      "kv",    # Key Vault
      "st",    # Storage Account
      "sql",   # SQL Server
      "acr",   # Container Registry
      "oai",   # Azure OpenAI
      "aks",   # AKS (API Server)
      "app",   # App Service
      "func",  # Azure Functions
      "cosmo", # Cosmos DB
      "sb",    # Service Bus
      "evh",   # Event Hub
      "redis", # Redis Cache
      "apim",  # API Management
      "ml",    # Machine Learning
      "cr"     # Cognitive Services
    ], var.resource_type_abbreviation)
    error_message = "Resource type abbreviation must be one of the supported types (kv, st, sql, acr, oai, aks, app, func, cosmo, sb, evh, redis, apim, ml, cr)."
  }
}

variable "private_connection_resource_id" {
  description = "The resource ID of the target Azure resource (Key Vault, Storage Account, etc.)"
  type        = string
}

variable "subresource_names" {
  description = "List of subresource names for the private endpoint connection. Examples: ['vault'] for Key Vault, ['blob', 'file'] for Storage, ['sqlServer'] for SQL"
  type        = list(string)

  validation {
    condition     = length(var.subresource_names) > 0
    error_message = "At least one subresource name must be specified."
  }
}

variable "is_manual_connection" {
  description = "Does the Private Endpoint require manual approval from the remote resource owner?"
  type        = bool
  default     = false
}

variable "request_message" {
  description = "A message passed to the owner of the remote resource when manual connection is required"
  type        = string
  default     = "Please approve this private endpoint connection"
}

variable "private_dns_zone_ids" {
  description = "List of Private DNS Zone IDs for automatic DNS registration. Leave empty to skip DNS integration."
  type        = list(string)
  default     = []
}

variable "ip_configurations" {
  description = "Custom IP configurations for the private endpoint (alternative to DNS zone group)"
  type = list(object({
    name               = string
    private_ip_address = string
    subresource_name   = string
    member_name        = optional(string, "default")
  }))
  default = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the private endpoint"
  type        = map(string)
  default     = {}
}
