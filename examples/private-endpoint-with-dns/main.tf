terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstategowrisha"
    container_name       = "tfstate"
    key                  = "examples/private-endpoint/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# ---------- Variables ----------

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "germanywestcentral"
}

variable "project" {
  type    = string
  default = "private-demo"
}

locals {
  default_tags = {
    environment = var.environment
    project     = var.project
    managed-by  = "terraform"
  }
}

# ---------- Resource Group ----------

module "rg" {
  source = "../../modules/resource-group"

  project      = var.project
  environment  = var.environment
  location     = var.location
  default_tags = local.default_tags
}

# ---------- Networking ----------

module "vnet" {
  source = "../../modules/vnet"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = module.rg.name
  address_space       = ["10.1.0.0/16"]

  subnets = [
    {
      name                              = "snet-privateendpoints"
      address_prefixes                  = ["10.1.1.0/24"]
      private_endpoint_network_policies = "Disabled"
    },
    {
      name              = "snet-workloads"
      address_prefixes  = ["10.1.2.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
  ]

  tags = local.default_tags
}

# ---------- Log Analytics ----------

module "log_analytics" {
  source = "../../modules/log-analytics"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = module.rg.name

  tags = local.default_tags
}

# ---------- Private DNS Zones ----------

# Key Vault Private DNS Zone
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.rg.name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "keyvault-vnet-link"
  resource_group_name   = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = module.vnet.vnet_id
  registration_enabled  = false
  tags                  = local.default_tags
}

# Storage Blob Private DNS Zone
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = module.rg.name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-vnet-link"
  resource_group_name   = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = module.vnet.vnet_id
  registration_enabled  = false
  tags                  = local.default_tags
}

# Storage File Private DNS Zone
resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = module.rg.name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "file-vnet-link"
  resource_group_name   = module.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = module.vnet.vnet_id
  registration_enabled  = false
  tags                  = local.default_tags
}

# ---------- Key Vault (Private) ----------

module "key_vault" {
  source = "../../modules/key-vault"

  project                       = var.project
  environment                   = var.environment
  location                      = var.location
  resource_group_name           = module.rg.name
  enable_rbac_authorization     = true
  public_network_access_enabled = false

  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = []
  }

  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.default_tags
}

# Private Endpoint for Key Vault
module "pe_keyvault" {
  source = "../../modules/private-endpoint"

  project                        = var.project
  environment                    = var.environment
  location                       = var.location
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]
  resource_type_abbreviation     = "kv"
  private_connection_resource_id = module.key_vault.vault_id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.keyvault.id]
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = local.default_tags
}

# ---------- Storage Account (Private) ----------

module "storage" {
  source = "../../modules/storage-account"

  project                       = var.project
  environment                   = var.environment
  location                      = var.location
  resource_group_name           = module.rg.name
  replication_type              = "LRS"
  public_network_access_enabled = false

  containers = [
    { name = "private-data" },
    { name = "backups" }
  ]

  network_rules = {
    default_action             = "Deny"
    virtual_network_subnet_ids = []
  }

  log_analytics_workspace_id = module.log_analytics.workspace_id

  tags = local.default_tags
}

# Private Endpoint for Storage Account (Blob)
module "pe_storage_blob" {
  source = "../../modules/private-endpoint"

  project                        = var.project
  environment                    = var.environment
  location                       = var.location
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]
  resource_type_abbreviation     = "st"
  private_connection_resource_id = module.storage.storage_account_id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.blob.id]
  log_analytics_workspace_id     = module.log_analytics.workspace_id

  tags = merge(local.default_tags, {
    subresource = "blob"
  })
}

# Private Endpoint for Storage Account (File)
module "pe_storage_file" {
  source = "../../modules/private-endpoint"

  project                        = var.project
  environment                    = var.environment
  location                       = var.location
  resource_group_name            = module.rg.name
  subnet_id                      = module.vnet.subnet_ids["snet-privateendpoints"]
  resource_type_abbreviation     = "st"
  private_connection_resource_id = module.storage.storage_account_id
  subresource_names              = ["file"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.file.id]
  instance                       = "02" # Different instance number for second endpoint

  tags = merge(local.default_tags, {
    subresource = "file"
  })
}

# ---------- Outputs ----------

output "resource_group_name" {
  value = module.rg.name
}

output "vnet_name" {
  value = module.vnet.vnet_name
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "key_vault_private_ip" {
  value       = module.pe_keyvault.private_ip_addresses
  description = "Private IP address of the Key Vault private endpoint"
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_blob_private_ip" {
  value       = module.pe_storage_blob.private_ip_addresses
  description = "Private IP address of the Storage blob private endpoint"
}

output "storage_file_private_ip" {
  value       = module.pe_storage_file.private_ip_addresses
  description = "Private IP address of the Storage file private endpoint"
}

output "private_dns_zones" {
  value = {
    keyvault = azurerm_private_dns_zone.keyvault.name
    blob     = azurerm_private_dns_zone.blob.name
    file     = azurerm_private_dns_zone.file.name
  }
  description = "Private DNS zones created for name resolution"
}
