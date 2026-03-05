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
  description = "Azure region (Note: OpenAI is only available in specific regions like eastus, swedencentral, francecentral, etc.)"
  type        = string
  default     = "swedencentral"
}

variable "location_abbreviations" {
  description = "Mapping of Azure regions to standard company abbreviations"
  type        = map(string)
  default = {
    "germanywestcentral" = "gwc"
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "swedencentral"      = "swc"
    "eastus"             = "eus"
    "southcentralus"     = "scus"
    "francecentral"      = "frc"
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU for the Cognitive Services Account (usually S0 for OpenAI)"
  type        = string
  default     = "S0"

  validation {
    condition     = contains(["S0"], var.sku_name)
    error_message = "Currently, only S0 is supported for Azure OpenAI."
  }
}

variable "custom_subdomain_name" {
  description = "Custom subdomain name for the OpenAI service. If left empty, one will be generated from company, project, environment."
  type        = string
  default     = ""
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled."
  type        = bool
  default     = false
}

variable "local_auth_enabled" {
  description = "Whether local authentication (API keys) is enabled. If false, Entra ID RBAC must be used."
  type        = bool
  default     = false
}

variable "outbound_network_access_restricted" {
  description = "Whether outbound network access is restricted."
  type        = bool
  default     = false
}

variable "network_acls" {
  description = "Network ACLs for the OpenAI service"
  type = object({
    default_action = optional(string, "Deny")
    ip_rules       = optional(list(string), [])
  })
  default = {
    default_action = "Deny"
  }
}

variable "deployments" {
  description = "List of OpenAI model deployments (e.g., gpt-4, text-embedding-ada-002)"
  type = list(object({
    name            = string
    model_format    = optional(string, "OpenAI")
    model_name      = string
    model_version   = string
    scale_type      = optional(string, "Standard")
    scale_capacity  = optional(number, 10) # in Thousands of Tokens per Minute (TPM)
    rai_policy_name = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
