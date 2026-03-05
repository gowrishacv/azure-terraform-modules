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
    key                  = "examples/minimal/terraform.tfstate"
  }

}

module "" {

}