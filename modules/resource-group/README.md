# Resource Group Module

Creates an Azure Resource Group with enforced tagging standards and naming conventions.

## Usage

```hcl
module "rg" {
  source = "../../modules/resource-group"

  name        = "rg-myapp-dev-gwc"
  location    = "germanywestcentral"
  environment = "dev"

  default_tags = {
    owner       = "platform-team"
    cost-center = "engineering"
  }

  extra_tags = {
    project = "landing-zone"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.75.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Resource group name (must start with `rg-`) | string | - | yes |
| location | Azure region | string | `germanywestcentral` | no |
| environment | Environment (dev, staging, prod) | string | - | yes |
| default_tags | Base tags for all resources | map(string) | see variables.tf | no |
| extra_tags | Additional tags to merge | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource Group ID |
| name | Resource Group name |
| location | Resource Group location |
| tags | Applied tags |

## Design Decisions

- **Naming validation**: Enforces `rg-` prefix to align with Azure naming conventions
- **Tag merging**: `default_tags` + `extra_tags` + auto-generated tags (environment, managed-by) are merged. This ensures every resource group has baseline governance tags
- **Lifecycle**: `created-date` tag is ignored in lifecycle to prevent unnecessary diffs
