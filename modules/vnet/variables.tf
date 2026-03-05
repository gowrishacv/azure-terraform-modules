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

variable "address_space" {
  description = "Address space for the VNet (CIDR notation)"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space must be provided."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "All address_space entries must be valid CIDR notation (e.g., 10.0.0.0/16)."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers. Empty list uses Azure-provided DNS"
  type        = list(string)
  default     = []
}

variable "ddos_protection_plan_id" {
  description = "ID of an existing Azure DDoS Protection Plan to attach to the VNet."
  type        = string
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID to send VNet diagnostic logs to."
  type        = string
  default     = ""
}

variable "subnets" {
  description = "List of subnet configurations with optional NSG and UDR IDs"
  type = list(object({
    name                                          = string
    address_prefixes                              = list(string)
    network_security_group_id                     = optional(string)
    route_table_id                                = optional(string)
    service_endpoints                             = optional(list(string))
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    delegation = optional(object({
      name                       = string
      service_delegation_name    = string
      service_delegation_actions = list(string)
    }))
  }))
  default = []
}

variable "peerings" {
  description = "List of VNet peering configurations"
  type = list(object({
    name                    = string
    remote_vnet_id          = string
    allow_vnet_access       = optional(bool, true)
    allow_forwarded_traffic = optional(bool, false)
    allow_gateway_transit   = optional(bool, false)
    use_remote_gateways     = optional(bool, false)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the VNet"
  type        = map(string)
  default     = {}
}
