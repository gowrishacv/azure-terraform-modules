<div align="center">
  <img src="https://raw.githubusercontent.com/hashicorp/terraform-website/master/public/img/logo-text.svg" width="300" alt="Terraform Logo"/>
  <br/>
  <h1>☁️ Azure Enterprise Terraform Modules</h1>
  <p><b>Production-grade, highly secure, and reusable Terraform modules for Azure infrastructure.</b></p>
  
  [![Terraform Version](https://img.shields.io/badge/Terraform-%3E%3D%201.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
  [![AzureRM Provider](https://img.shields.io/badge/AzureRM-%3E%3D%203.75.0-0089D6?logo=microsoft-azure)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![Testing: Terratest](https://img.shields.io/badge/Testing-Terratest-00ADD8?logo=go)](https://terratest.gruntwork.io/)
</div>

<br/>

Welcome to the **Azure Enterprise Terraform Modules** repository! 👋

If you are looking for battle-tested infrastructure-as-code snippets that are ready to be deployed into strict corporate environments, you're in the right place. We built these modules to stop reinventing the wheel every time we need a new Virtual Machine, Kubernetes Cluster, or Key Vault.

## ✨ Why use these modules?

We've baked in enterprise best practices so you don't have to:

- 🏷️ **Tagging Enforcement:** Every resource strictly adheres to a standard tagging inheritance model (environment, owner, cost center).
- 🔒 **Secure by Default:** Public network access is disabled by default, HTTPS is enforced, and TLS 1.2+ is the minimum standard.
- 🔑 **Least Privilege Identity:** We strongly prefer System-Assigned Managed Identities over messy Service Principals.
- 🧪 **Automated Validation:** Every single module is covered by [Terratest](https://terratest.gruntwork.io/) to guarantee that deployments actually work before they hit production.
- 📦 **100% Parameterized:** Absolutely zero hardcoded values.

---

## 🏗️ Architecture & Available Modules

Our module ecosystem is designed to be highly composable. Use one, or use them all!

| Module | Purpose | Key Enterprise Features |
|--------|---------|-------------------------|
| 🧊 **[Resource Group](./modules/resource-group/)** | Foundation | Tag inheritance, strict naming conventions, management locks |
| 🌐 **[Virtual Network](./modules/vnet/)** | Networking | Granular subnetting, service endpoints, DNS delegation |
| 🛡️ **[Network Security Group](./modules/nsg/)** | Firewall | Centralized rule priority management, flow logs |
| 🔐 **[Key Vault](./modules/key-vault/)** | Secrets | Azure RBAC integration, soft delete, purge protection |
| 💾 **[Storage Account](./modules/storage-account/)** | Data | Encryption at rest, network rules, aggressive lifecycle policies |
| ⚙️ **[Virtual Machine](./modules/virtual-machine/)** | Compute | Linux/Windows support, Azure Monitor Agent extensions |
| 🚀 **[App Service](./modules/app-service/)** | Web Apps | Managed Identity, VNet integration out-of-the-box |
| 🤖 **[Azure OpenAI](./modules/openai/)** | AI/ML | Deep Entra ID RBAC, Private Endpoints, Multiple Deployments |
| 📦 **[Container Registry](./modules/acr/)** | Artifacts | Premium SKU features, private endpoints, geo-replication |
| 🚢 **[AKS Cluster](./modules/aks-cluster/)** | Kubernetes | Entra ID RBAC, Azure CNI networking, automated node pools |
| 📊 **[Log Analytics](./modules/log-analytics/)** | Monitoring | Centralized retention, capacity planning |
| 🗄️ **[SQL Server](./modules/sql-server/)** | Database | Entra ID-only auth, vulnerability assessments, firewall rules |

---

## 🚀 Quick Start Guide

### 1. Prerequisites

Before you begin, ensure you have the following installed:

- **Terraform** >= `1.5.0`
- **Go** >= `1.21` (Only strictly required if running tests)
- Authenticated via Azure CLI (`az login`)

### 2. Set Up Your Remote State

First, you'll want to initialize a storage account to keep your `.tfstate` files safe and shared with your team:

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

### 3. Deploy an Example

We provide ready-to-use examples for every module. Let's deploy the minimum foundational setup:

```bash
# 1. Clone the repository
git clone https://github.com/gowrishacv/azure-terraform-modules.git
cd azure-terraform-modules/examples/minimal

# 2. Initialize Terraform (downloads providers)
terraform init

# 3. See what will be created
terraform plan -var-file="terraform.tfvars"

# 4. Deploy it to Azure!
terraform apply -var-file="terraform.tfvars"
```

---

## 🧪 Running Automated Tests

Because infrastructure is code, we treat it like code. Every module has a companion Go test file using the **Terratest** framework.

When you run these tests, they will literally spin up the infrastructure in Azure, verify it matches our assertions, and immediately destroy it. Clean and painless!

To run a test (e.g., for the Key Vault module):

```bash
cd modules/key-vault/tests

# Install dependencies
go mod tidy

# Run the test (times out after 60 mins due to Azure provisioning times)
go test -v -timeout 60m
```

---

## 🤝 Contributing

We love contributions! If you'd like to improve a module or add a new one:

1. Create a feature branch (`git checkout -b feature/amazing-new-module`).
2. Implement your module and **make sure to write a Terratest for it**.
3. Commit changes with a descriptive message.
4. Open a Pull Request!

## 📄 License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.
