<div align="center">
  <img src="https://raw.githubusercontent.com/hashicorp/terraform-website/master/public/img/logo-text.svg" width="300" alt="Terraform Logo"/>
  <br/>
  <h1>Azure Enterprise Terraform Modules</h1>
  <p><b>Production-grade, security-hardened, and reusable Terraform modules for Azure infrastructure.</b></p>

  [![Terraform Version](https://img.shields.io/badge/Terraform-%3E%3D%201.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
  [![AzureRM Provider](https://img.shields.io/badge/AzureRM-~%3E%203.75-0089D6?logo=microsoft-azure)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![Testing: Terratest](https://img.shields.io/badge/Testing-Terratest-00ADD8?logo=go)](https://terratest.gruntwork.io/)
</div>

<br/>

A library of **12 composable Terraform modules** for Azure, designed for enterprise environments with strict security, compliance, and operational requirements.

## Security Posture

These modules are aligned with the **CIS Azure Foundations Benchmark** and the **Azure Well-Architected Framework**:

- **Network isolation** - Public access disabled by default across all modules
- **TLS 1.2+** enforced on all services (SQL, Storage, Key Vault, App Service)
- **System-Assigned Managed Identities** preferred over service principals and shared keys
- **Baseline deny rules** on NSGs with validation preventing internet-exposed high-risk ports
- **Soft delete and purge protection** enabled on Key Vault (90-day retention)
- **Microsoft Defender** enabled for SQL and Storage
- **Diagnostic logging** to Log Analytics on all resources
- **Encryption at host** support for Virtual Machines (CIS 7.2)
- **Local account disabled** on AKS (Entra ID-only authentication)
- **Azure Policy add-on** enabled on AKS clusters

---

## Available Modules

| Module | Purpose | Key Security Features |
|--------|---------|----------------------|
| [Resource Group](./modules/resource-group/) | Foundation | Tag inheritance, management locks, RBAC role assignments |
| [Virtual Network](./modules/vnet/) | Networking | CIDR validation, DDoS protection, subnet delegation, peering |
| [Network Security Group](./modules/nsg/) | Firewall | Baseline deny-all rules, high-risk port blocking validation, diagnostic logging |
| [Key Vault](./modules/key-vault/) | Secrets | RBAC authorization, purge protection, network ACLs, audit diagnostics |
| [Storage Account](./modules/storage-account/) | Data | Shared key disabled, network deny rules, Defender for Storage, blob diagnostics |
| [Virtual Machine](./modules/virtual-machine/) | Compute | Encryption at host, boot diagnostics, SSH key auth, Azure Monitor Agent |
| [App Service](./modules/app-service/) | Web Apps | Managed Identity, VNet integration, FTPS disabled, HTTP/2 enabled |
| [Azure OpenAI](./modules/openai/) | AI/ML | Entra ID RBAC, network ACLs, managed identity, multi-model deployments |
| [Container Registry](./modules/acr/) | Artifacts | Content trust, geo-replication, IP-based network rules, admin disabled |
| [AKS Cluster](./modules/aks-cluster/) | Kubernetes | Private cluster, Entra ID RBAC, Azure Policy, Defender, control plane audit logs |
| [Log Analytics](./modules/log-analytics/) | Monitoring | 90-day retention default, private ingestion/query, daily quota controls |
| [SQL Server](./modules/sql-server/) | Database | Entra ID-only auth, identity block, firewall validation, vulnerability assessments |

---

## Quick Start

### Prerequisites

- **Terraform** >= `1.5.0`
- **Go** >= `1.21` (only required for running tests)
- Azure CLI authenticated (`az login`)

### 1. Set Up Remote State

```bash
az group create --name rg-terraform-state --location germanywestcentral

az storage account create \
  --name <your-state-account> \
  --resource-group rg-terraform-state \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name tfstate \
  --account-name <your-state-account>
```

### 2. Deploy

```bash
git clone https://github.com/gowrishacv/azure-terraform-modules.git
cd azure-terraform-modules/examples/minimal

terraform init
terraform plan
terraform apply
```

See [`examples/complete/`](./examples/complete/) for a full-stack deployment (Resource Group, VNet, NSG, Key Vault, Storage, App Service, AKS).

---

## Module Usage

Each module follows a consistent interface with enterprise naming conventions:

```hcl
module "key_vault" {
  source = "./modules/key-vault"

  company_prefix = "acme"
  project        = "platform"
  environment    = "prod"
  location       = "germanywestcentral"

  resource_group_name       = module.rg.name
  enable_rbac_authorization = true

  tags = local.default_tags
}
# Creates: kv-acme-platform-prod-gwc-01
```

### Naming Convention

All resources follow the pattern: `{type}-{company}-{project}-{env}-{region}-{instance}`

| Resource | Example Name |
|----------|-------------|
| Resource Group | `rg-acme-platform-prod-gwc-01` |
| Virtual Network | `vnet-acme-platform-prod-gwc-01` |
| NSG | `nsg-acme-platform-prod-gwc-01` |
| Key Vault | `kv-acme-platform-prod-gwc-01` |
| Storage Account | `stacmeplatformprodgwc01` |
| AKS Cluster | `aks-acme-platform-prod-gwc-01` |

---

## Repository Structure

```
.
├── modules/
│   ├── resource-group/      # Foundation: RG + locks + RBAC
│   ├── vnet/                 # Networking: VNet + subnets + peering
│   ├── nsg/                  # Security: NSG + rules + diagnostics
│   ├── key-vault/            # Secrets: KV + RBAC + audit logs
│   ├── storage-account/      # Storage: Blob + Defender + diagnostics
│   ├── virtual-machine/      # Compute: Linux/Windows VMs + AMA
│   ├── app-service/          # Web: App Service + diagnostics
│   ├── openai/               # AI: Azure OpenAI + deployments
│   ├── acr/                  # Registry: ACR + geo-replication
│   ├── aks-cluster/          # K8s: AKS + node pools + Defender
│   ├── log-analytics/        # Monitoring: Workspace
│   └── sql-server/           # Database: SQL + Defender + auditing
├── examples/
│   ├── minimal/              # RG + VNet only
│   └── complete/             # Full-stack deployment
├── environments/
│   ├── dev/                  # Dev backend + variables
│   └── prod/                 # Prod backend + variables
└── .gitignore
```

---

## Running Tests

Modules with test coverage use [Terratest](https://terratest.gruntwork.io/) (Go):

```bash
cd modules/key-vault/tests
go mod tidy
go test -v -timeout 60m
```

Tests deploy real infrastructure, validate assertions, then destroy everything.

---

## Contributing

1. Create a feature branch (`git checkout -b feature/new-module`)
2. Implement your module with tests
3. Commit with a descriptive message
4. Open a Pull Request

## License

MIT License. See [`LICENSE`](./LICENSE) for details.
