# Network Security Group Module

Creates an Azure NSG with configurable security rules and subnet associations.

## Usage

```hcl
module "nsg_aks" {
  source = "../../modules/nsg"

  name                = "nsg-aks-dev-gwc"
  location            = module.rg.location
  resource_group_name = module.rg.name

  subnet_ids = [module.vnet.subnet_ids["snet-aks"]]

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

  tags = module.rg.tags
}
```

## Design Decisions

- **Rules as separate resources**: Uses `azurerm_network_security_rule` instead of inline rules. This prevents full NSG replacement when a single rule changes
- **Subnet association built-in**: Accepts subnet IDs directly so NSG-to-subnet mapping is explicit
- **Priority validation**: Enforces Azure's valid range (100-4096) at the Terraform level
