terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
  }
}

locals {
  location_abbr = lookup(var.location_abbreviations, var.location, var.location)

  # Base name formats which will have the '-xx' index appended
  vm_base_name  = lower("vm-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}")
  nic_base_name = lower("nic-vm-${var.company_prefix}-${var.project}-${var.environment}-${local.location_abbr}")
}

# -------------------------------------------------------------
# Network Interfaces
# -------------------------------------------------------------
resource "azurerm_network_interface" "this" {
  count = var.vm_count

  name                = format("%s-%02d", local.nic_base_name, var.instance_start_index + count.index)
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# -------------------------------------------------------------
# Linux Virtual Machine
# -------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "linux" {
  count = var.os_type == "Linux" ? var.vm_count : 0

  name                = format("%s-%02d", local.vm_base_name, var.instance_start_index + count.index)
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # Either SSH key or password (prefer SSH if passed)
  disable_password_authentication = var.ssh_public_key != "" ? true : false

  network_interface_ids = [
    azurerm_network_interface.this[count.index].id
  ]

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  encryption_at_host_enabled = var.encryption_at_host_enabled

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = var.source_image_reference["publisher"]
    offer     = var.source_image_reference["offer"]
    sku       = var.source_image_reference["sku"]
    version   = var.source_image_reference["version"]
  }

  boot_diagnostics {}

  # Essential for modern enterprise workloads
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# -------------------------------------------------------------
# Windows Virtual Machine
# -------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "windows" {
  count = var.os_type == "Windows" ? var.vm_count : 0

  name                = format("%s-%02d", local.vm_base_name, var.instance_start_index + count.index)
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  encryption_at_host_enabled = var.encryption_at_host_enabled

  network_interface_ids = [
    azurerm_network_interface.this[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = var.source_image_reference["publisher"]
    offer     = var.source_image_reference["offer"]
    sku       = var.source_image_reference["sku"]
    version   = var.source_image_reference["version"]
  }

  boot_diagnostics {}

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# -------------------------------------------------------------
# Azure Monitor Agent (AMA) extensions
# -------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "ama_linux" {
  count = var.os_type == "Linux" && var.data_collection_rule_id != "" ? var.vm_count : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.linux[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.25"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}

resource "azurerm_virtual_machine_extension" "ama_windows" {
  count = var.os_type == "Windows" && var.data_collection_rule_id != "" ? var.vm_count : 0

  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}

# -------------------------------------------------------------
# DCR Associations (Stamps monitoring policy to all VMs)
# -------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule_association" "linux_dcr" {
  count = var.os_type == "Linux" && var.data_collection_rule_id != "" ? var.vm_count : 0

  name                    = "ama-dcr-assoc-linux-${count.index}"
  target_resource_id      = azurerm_linux_virtual_machine.linux[count.index].id
  data_collection_rule_id = var.data_collection_rule_id

  depends_on = [azurerm_virtual_machine_extension.ama_linux]
}

resource "azurerm_monitor_data_collection_rule_association" "windows_dcr" {
  count = var.os_type == "Windows" && var.data_collection_rule_id != "" ? var.vm_count : 0

  name                    = "ama-dcr-assoc-windows-${count.index}"
  target_resource_id      = azurerm_windows_virtual_machine.windows[count.index].id
  data_collection_rule_id = var.data_collection_rule_id

  depends_on = [azurerm_virtual_machine_extension.ama_windows]
}
