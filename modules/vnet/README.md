# Virtual Network Module

Creates an Azure Virtual Network with subnets, service endpoints, delegations, and optional VNet peering.

## Usage

```hcl
module "vnet" {
  source = "../../modules/vnet"

  name                = "vnet-platform-dev-gwc"
  location            = module.rg.location
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name             = "snet-aks"
      address_prefixes = ["10.0.0.0/22"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    },
    {
      name             = "snet-appservice"
      address_prefixes = ["10.0.4.0/24"]
      delegation = {
        name                       = "appservice-delegation"
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

  tags = module.rg.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | VNet name (must start with `vnet-`) | string | - | yes |
| location | Azure region | string | - | yes |
| resource_group_name | Resource group name | string | - | yes |
| address_space | CIDR blocks for VNet | list(string) | - | yes |
| dns_servers | Custom DNS servers | list(string) | `[]` | no |
| subnets | Subnet configurations | list(object) | `[]` | no |
| peerings | VNet peering configurations | list(object) | `[]` | no |
| tags | Resource tags | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | VNet resource ID |
| name | VNet name |
| address_space | VNet address space |
| subnet_ids | Map of subnet name to ID |
| subnet_address_prefixes | Map of subnet name to CIDR |

## Design Decisions

- **Subnet as for_each**: Uses `for_each` instead of `count` so subnets can be added or removed without forcing recreation of unrelated subnets
- **Optional delegation**: Supports Azure service delegation (App Service, Container Instances, etc.) via dynamic blocks
- **Peering built-in**: Avoids separate peering modules. Keeps network topology in one place
