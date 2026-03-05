# Azure Terraform Modules

Production-grade, reusable Terraform modules for Azure infrastructure. Built for enterprise environments with consistent tagging, naming conventions, and security defaults.

## Architecture

```
├── modules/
│   ├── resource-group/       # Resource Group with enforced tagging
│   ├── vnet/                 # Virtual Network with subnets and service endpoints
│   ├── nsg/                  # Network Security Groups with rule management
│   ├── key-vault/            # Key Vault with access policies and private endpoint
│   ├── storage-account/      # Storage Account with security hardening
│   ├── app-service/          # App Service with managed identity and VNet integration
│   └── aks-cluster/          # AKS with node pools, RBAC, and network policy
├── examples/
│   ├── complete/             # Full deployment using all modules
│   └── minimal/              # Minimal example with core modules only
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── .github/workflows/        # CI/CD for Terraform plan and apply
```

## Design Principles

- **Tagging enforcement**: Every resource inherits a base tag set (environment, owner, cost center, managed-by)
- **Secure defaults**: Public access disabled, HTTPS enforced, TLS 1.2 minimum where applicable
- **Least privilege**: Managed identities preferred over service principals
- **Remote state**: Azure Storage backend with state locking via blob lease
- **No hardcoded values**: Everything parameterized through variables

## Prerequisites

- Terraform >= 1.5.0
- AzureRM Provider >= 3.75.0
- Azure CLI authenticated (`az login`)
- Storage Account for remote state (see [backend setup](#backend-setup))

## Quick Start

```bash
# Clone the repo
git clone https://github.com/gowrishacv/azure-terraform-modules.git
cd azure-terraform-modules/examples/minimal

# Initialize with remote backend
terraform init

# Review the plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"
```

## Backend Setup

Create a Storage Account for Terraform state before using these modules:

```bash
az group create --name rg-terraform-state --location germanywestcentral
az storage account create \
  --name sttfstategowrisha \
  --resource-group rg-terraform-state \
  --sku Standard_LRS \
  --encryption-services blob
az storage container create \
  --name tfstate \
  --account-name sttfstategowrisha
```

## Module Reference

| Module | Description | Key Features |
|--------|-------------|--------------|
| [resource-group](./modules/resource-group/) | Resource Group with enforced tagging | Tag inheritance, naming convention |
| [vnet](./modules/vnet/) | Virtual Network with subnets | Service endpoints, delegation, DNS |
| [nsg](./modules/nsg/) | Network Security Groups | Rule priority management, flow logs |
| [key-vault](./modules/key-vault/) | Key Vault | RBAC, soft delete, purge protection |
| [storage-account](./modules/storage-account/) | Storage Account | Encryption, network rules, lifecycle |
| [app-service](./modules/app-service/) | App Service (Linux) | Managed identity, VNet integration |
| [aks-cluster](./modules/aks-cluster/) | Azure Kubernetes Service | RBAC, CNI networking, node pools |

## Environments

Each environment folder contains its own `terraform.tfvars` and backend config. This keeps state files isolated per environment.

```bash
cd environments/dev
terraform init -backend-config="backend.tfvars"
terraform plan -var-file="terraform.tfvars"
```

## Contributing

1. Create a feature branch (`git checkout -b feature/add-redis-module`)
2. Commit changes with meaningful messages
3. Open a Pull Request with description of what changed and why

## License

MIT
