resource "random_id" "prefix" {
  byte_length = 4
}

locals {
  name_prefix = "oaitest${random_id.prefix.hex}"
  # OpenAI is only available in select regions
  location = "swedencentral"
}

resource "azurerm_resource_group" "test" {
  name     = "rg-${local.name_prefix}"
  location = local.location
}

module "openai" {
  source = "../../"

  company_prefix      = "tst"
  project             = random_id.prefix.hex
  environment         = "dev"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  sku_name                      = "S0"
  public_network_access_enabled = true # Needed for easy Terratest 

  deployments = [
    {
      name           = "gpt-35-turbo-test"
      model_format   = "OpenAI"
      model_name     = "gpt-35-turbo"
      model_version  = "0301"
      scale_type     = "Standard"
      scale_capacity = 1
    }
  ]
}

output "openai_name" {
  value = module.openai.openai_name
}

output "openai_endpoint" {
  value = module.openai.openai_endpoint
}
