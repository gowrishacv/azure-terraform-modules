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

variable "sql_version" {
  description = "The version for the MS SQL Server. Valid values are: 2.0, 12.0"
  type        = string
  default     = "12.0"
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this server"
  type        = bool
  default     = false
}

variable "azuread_admin_group_name" {
  description = "The display name of the Entra ID Group that should be the SQL Admin"
  type        = string
  default     = ""
}

variable "azuread_authentication_only" {
  description = "Specifies whether only Azure AD authentication can be used"
  type        = bool
  default     = true
}

variable "sql_admin_username" {
  description = "The administrator login name for the SQL Server. Only used if azuread_authentication_only is false"
  type        = string
  default     = ""
}

variable "sql_admin_password" {
  description = "The administrator password for the SQL Server. Only used if azuread_authentication_only is false"
  type        = string
  default     = ""
  sensitive   = true
}

variable "firewall_rules" {
  description = "Map of firewall rules to create on the server"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, rule in var.firewall_rules :
      !(rule.start_ip_address == "0.0.0.0" && rule.end_ip_address == "255.255.255.255")
    ])
    error_message = "Firewall rules must not allow the entire internet (0.0.0.0 - 255.255.255.255). Use specific IP ranges."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for SQL Security Audit Events"
  type        = string
  default     = ""
}

variable "email_security_alerts_to_admins" {
  description = "Should security alerts be sent to the subscription administrators?"
  type        = bool
  default     = true
}

variable "security_alert_emails" {
  description = "List of email addresses to send security alerts to"
  type        = list(string)
  default     = []
}

variable "alert_retention_days" {
  description = "How many days to keep security alerts. CIS recommends >= 90 days."
  type        = number
  default     = 90

  validation {
    condition     = var.alert_retention_days >= 90
    error_message = "Alert retention must be at least 90 days for compliance (CIS Azure Benchmark)."
  }
}

variable "vulnerability_assessment_storage_container_path" {
  description = "The blob container URL for vulnerability assessments. (Requires Managed Identity to have Contributor on the Storage Account) Leave empty to disable."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
