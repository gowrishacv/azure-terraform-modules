# Virtual Machine Module

Creates Azure Virtual Machines (Linux/Windows) with enterprise security: encryption at host, boot diagnostics, SSH key authentication, Azure Monitor Agent, system-assigned managed identity, and disk encryption.

## Usage

```hcl
module "virtual_machine" {
  source = "../../modules/virtual-machine"

  company_prefix = "acme"
  project        = "platform"
  environment    = "prod"
  location       = "germanywestcentral"

  resource_group_name = module.rg.name
  os_type             = "Linux"
  vm_count            = 3
  vm_size             = "Standard_D4s_v5"
  admin_username      = "azureuser"

  subnet_id = module.vnet.subnet_ids["snet-vm"]

  os_disk_caching              = "ReadWrite"
  os_disk_storage_account_type = "Premium_LRS"
  encryption_at_host_enabled   = true

  enable_boot_diagnostics = true
  boot_diagnostic_storage_account_uri = module.storage.primary_blob_endpoint

  log_analytics_workspace_id = module.log_analytics.workspace_id
  enable_azure_monitor_agent = true

  tags = module.rg.tags
}
```

## Design Decisions

- **Encryption at host**: CIS 7.2 compliance; encrypts VM disks at the hypervisor level
- **SSH key authentication preferred**: Disables password login; SSH public keys only for Linux VMs
- **System-Assigned Managed Identity**: Keyless authentication for Azure services (no credential management)
- **Azure Monitor Agent (AMA)**: Modern replacement for Legacy Monitoring Agent; sends logs and metrics to Log Analytics
- **Boot diagnostics enabled**: Troubleshoots startup failures without RDP/SSH access
- **Premium storage default**: SSD-backed disks for predictable performance; cost optimizable per environment
- **Disk encryption enabled**: Uses customer-managed or platform-managed encryption at rest
