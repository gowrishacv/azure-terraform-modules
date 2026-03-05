terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstategowrisha"
    container_name       = "tfstate"
    key                  = "examples/complete/terraform.tfstate"
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
  default = "platform"
}

locals {
  suffix = "${var.project}-${var.environment}-gwc"
  default_tags = {
    environment = var.environment
    project     = var.project
    owner       = "cloud-platform-team"
    cost-center = "infrastructure"
    managed-by  = "terraform"
  }
}

# ---------- Resource Group ----------

module "rg" {
  source = "../../modules/resource-group"

  name        = "rg-${local.suffix}"
  location    = var.location
  environment = var.environment
  default_tags = local.default_tags
}

# ---------- Networking ----------

module "vnet" {
  source = "../../modules/vnet"

  name                = "vnet-${local.suffix}"
  location            = module.rg.location
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name              = "snet-aks"
      address_prefixes  = ["10.0.0.0/22"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    },
    {
      name             = "snet-appservice"
      address_prefixes = ["10.0.4.0/24"]
      delegation = {
        name                       = "appservice"
        service_delegation_name    = "Microsoft.Web/serverFarms"
        service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    },
    {
      name                              = "snet-privateendpoints"
      address_prefixes                  = ["10.0.5.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  ]

  tags = local.default_tags
}

module "nsg_aks" {
  source = "../../modules/nsg"

  name                = "nsg-aks-${local.suffix}"
  location            = module.rg.location
  resource_group_name = module.rg.name
  subnet_ids          = [module.vnet.subnet_ids["snet-aks"]]

  rules = [
    {
      name                       = "allow-https-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "deny-all-inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  tags = local.default_tags
}

# ---------- Key Vault ----------

module "key_vault" {
  source = "../../modules/key-vault"

  name                          = "kv-${local.suffix}"
  location                      = module.rg.location
  resource_group_name           = module.rg.name
  enable_rbac_authorization     = true
  public_network_access_enabled = false

  network_acls = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["snet-aks"]]
  }

  tags = local.default_tags
}

# ---------- Storage Account ----------

module "storage" {
  source = "../../modules/storage-account"

  name                = "st${var.project}${var.environment}gwc"
  location            = module.rg.location
  resource_group_name = module.rg.name
  replication_type    = "ZRS"

  containers = [
    { name = "artifacts" },
    { name = "backups" }
  ]

  network_rules = {
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["snet-aks"]]
  }

  tags = local.default_tags
}

# ---------- App Service ----------

module "app_service" {
  source = "../../modules/app-service"

  name                       = "app-api-${local.suffix}"
  service_plan_name          = "asp-api-${local.suffix}"
  location                   = module.rg.location
  resource_group_name        = module.rg.name
  os_type                    = "Linux"
  sku_name                   = "P1v3"
  vnet_integration_subnet_id = module.vnet.subnet_ids["snet-appservice"]

  application_stack = {
    dotnet_version = "8.0"
  }

  app_settings = {
    ASPNETCORE_ENVIRONMENT = "Development"
    KeyVaultUri            = module.key_vault.vault_uri
  }

  tags = local.default_tags
}

# ---------- AKS Cluster ----------

module "aks" {
  source = "../../modules/aks-cluster"

  name                    = "aks-${local.suffix}"
  location                = module.rg.location
  resource_group_name     = module.rg.name
  dns_prefix              = "aks-${var.project}-${var.environment}"
  private_cluster_enabled = true
  sku_tier                = "Standard"

  default_node_pool = {
    vm_size        = "Standard_D4s_v5"
    node_count     = 3
    min_count      = 3
    max_count      = 10
    vnet_subnet_id = module.vnet.subnet_ids["snet-aks"]
  }

  additional_node_pools = [
    {
      name       = "workload"
      vm_size    = "Standard_D8s_v5"
      node_count = 2
      min_count  = 2
      max_count  = 20
      node_labels = {
        "workload-type" = "application"
      }
    }
  ]

  enable_secret_store_csi = true

  tags = local.default_tags
}

# ---------- Outputs ----------

output "resource_group_name" {
  value = module.rg.name
}

output "aks_cluster_name" {
  value = module.aks.name
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "app_service_hostname" {
  value = module.app_service.default_hostname
}
