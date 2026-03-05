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
    key                  = "examples/minimal/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
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
  default = "demo"
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

  project     = var.project
  environment = var.environment
  location    = var.location

  default_tags = local.default_tags
}

# ---------- Networking ----------

module "vnet" {
  source = "../../modules/vnet"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name             = "snet-default"
      address_prefixes = ["10.0.1.0/24"]
    }
  ]

  tags = local.default_tags
}

# ---------- Outputs ----------

output "resource_group_name" {
  value = module.rg.name
}

output "vnet_name" {
  value = module.vnet.vnet_name
}
