# Private Endpoint Example with DNS Integration

This example demonstrates how to deploy Azure resources with **private endpoints** for secure, private connectivity without public internet exposure.

## What Gets Deployed

1. **Resource Group** - Container for all resources
2. **Virtual Network** with two subnets:
   - `snet-privateendpoints` - Dedicated subnet for private endpoints
   - `snet-workloads` - Subnet for VMs/workloads
3. **Private DNS Zones**:
   - `privatelink.vaultcore.azure.net` (Key Vault)
   - `privatelink.blob.core.windows.net` (Storage Blob)
   - `privatelink.file.core.windows.net` (Storage File)
4. **Key Vault** (private, no public access)
5. **Private Endpoint for Key Vault** with DNS integration
6. **Storage Account** (private, no public access)
7. **Private Endpoint for Storage (Blob)** with DNS integration
8. **Private Endpoint for Storage (File)** with DNS integration
9. **Log Analytics Workspace** for diagnostic logging

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Virtual Network (10.1.0.0/16)                 │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  snet-privateendpoints (10.1.1.0/24)     │  │
│  │                                          │  │
│  │  • PE: Key Vault (10.1.1.4)             │  │
│  │  • PE: Storage Blob (10.1.1.5)          │  │
│  │  • PE: Storage File (10.1.1.6)          │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  snet-workloads (10.1.2.0/24)           │  │
│  │                                          │  │
│  │  VMs/Apps access services via private    │  │
│  │  IPs using Private DNS resolution        │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘

            ▼ Private DNS Zones ▼

   mykv.vault.azure.net → 10.1.1.4
   mystorage.blob.core.windows.net → 10.1.1.5
   mystorage.file.core.windows.net → 10.1.1.6
```

## Prerequisites

- Terraform >= 1.5.0
- Azure CLI authenticated (`az login`)
- Terraform backend configured (see `backend` block in main.tf)

## Deployment

```bash
cd examples/private-endpoint-with-dns

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

## Testing Private Connectivity

After deployment, test from a VM in the same VNet:

### 1. Deploy a Test VM (Optional)

```bash
# Add this to main.tf or deploy separately
module "test_vm" {
  source = "../../modules/virtual-machine"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = module.rg.name
  subnet_id           = module.vnet.subnet_ids["snet-workloads"]
  vm_size             = "Standard_B2s"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")

  tags = local.default_tags
}
```

### 2. Validate DNS Resolution

SSH into the VM and test DNS:

```bash
# Key Vault
nslookup kv-acme-private-demo-dev-gwc-01.vault.azure.net
# Should resolve to private IP (10.1.1.x)

# Storage Blob
nslookup stacmeprivatedemodgwc01.blob.core.windows.net
# Should resolve to private IP (10.1.1.x)

# Storage File
nslookup stacmeprivatedemodgwc01.file.core.windows.net
# Should resolve to private IP (10.1.1.x)
```

### 3. Test Connectivity

```bash
# Key Vault (requires authentication)
curl -I https://kv-acme-private-demo-dev-gwc-01.vault.azure.net

# Storage (requires authentication)
curl -I https://stacmeprivatedemodgwc01.blob.core.windows.net
```

**Expected Result**: Connection succeeds via private IP, not public internet.

### 4. Verify from Outside VNet

From your local machine (outside the VNet):

```bash
nslookup kv-acme-private-demo-dev-gwc-01.vault.azure.net
# Should resolve to public IP (e.g., 20.x.x.x)

curl -I https://kv-acme-private-demo-dev-gwc-01.vault.azure.net
# Should FAIL with connection timeout (public access disabled)
```

## Security Benefits

✅ **Zero public internet exposure**: All traffic stays within Azure backbone
✅ **No firewall rules needed**: Private endpoints bypass storage/Key Vault firewalls
✅ **Automatic DNS**: Services resolve to private IPs within VNet
✅ **CIS compliance**: Meets CIS Azure Foundations Benchmark requirements
✅ **Audit logging**: All connection events logged to Log Analytics

## Cost Estimate

| Resource | Monthly Cost (Germany West Central) |
|----------|-------------------------------------|
| Private Endpoint (3x) | ~$21.60 ($7.20 each) |
| Private DNS Zones (3x) | ~$1.50 ($0.50 each) |
| Key Vault | ~$0.03 (pay per operation) |
| Storage Account | ~$0.18 (100 GB LRS) |
| Log Analytics | ~$2.30 (5 GB ingestion) |
| **Total** | **~$25.61/month** |

*Prices are estimates and may vary.*

## Cleanup

```bash
terraform destroy
```

## Next Steps

- Add more services (SQL Server, ACR, Azure OpenAI)
- Integrate with AKS using Private Link
- Configure Network Security Groups (NSGs) for additional security
- Set up Azure Bastion for secure VM access

## References

- [Azure Private Endpoint Documentation](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Private Link DNS Integration](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [CIS Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure)
