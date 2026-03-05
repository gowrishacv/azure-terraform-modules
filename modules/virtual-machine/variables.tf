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

variable "instance_start_index" {
  description = "Starting index for instance numbering if spinning up multiple VMs (e.g., 1 for vm-01, vm-02)"
  type        = number
  default     = 1
}

variable "vm_count" {
  description = "Number of VMs to stamp out in this deployment"
  type        = number
  default     = 1
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

variable "subnet_id" {
  description = "The ID of the Subnet where the Network Interfaces will be attached"
  type        = string
}

variable "os_type" {
  description = "Operating System type to deploy"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "The OS type must be either 'Linux' or 'Windows'."
  }
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  type        = string
  default     = "Standard_B2ms"
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "The admin password for Windows VMs. Must be 12-123 characters with uppercase, lowercase, number and special character."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = var.admin_password == "" || (length(var.admin_password) >= 12 && length(var.admin_password) <= 123)
    error_message = "Admin password must be between 12 and 123 characters long."
  }
}

variable "ssh_public_key" {
  description = "SSH Public Key for Linux VMs. Required when os_type is Linux."
  type        = string
  default     = ""
}

variable "encryption_at_host_enabled" {
  description = "Enable encryption at host for OS and temp disks (CIS 7.2). Requires Microsoft.Compute/EncryptionAtHost feature registered on the subscription."
  type        = bool
  default     = false
}

variable "source_image_reference" {
  description = "The image reference for the VM OS"
  type        = map(string)
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "os_disk_type" {
  description = "The type of Managed Disk for the OS"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "data_collection_rule_id" {
  description = "The ID of the Log Analytics Data Collection Rule (DCR). If provided, Azure Monitor Agent is installed and associated."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
