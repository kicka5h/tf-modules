mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  virtual_machines = {
    web = {
      name           = "vm-web-01"
      os_type        = "linux"
      size           = "Standard_D2s_v3"
      admin_username = "azureadmin"
      admin_ssh_key = {
        public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7 test@key"
      }
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/web"
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
    }
    dc = {
      name           = "vm-dc-01"
      os_type        = "windows"
      size           = "Standard_D4s_v3"
      admin_username = "azureadmin"
      admin_password = "P@ssw0rd1234!"
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/ad"
      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-datacenter-g2"
        version   = "latest"
      }
      data_disks = {
        ntds = {
          name         = "vm-dc-01-ntds"
          disk_size_gb = 64
          lun          = 0
        }
      }
    }
  }
}

run "creates_linux_vm" {
  command = plan

  assert {
    condition     = length(azurerm_linux_virtual_machine.this) == 1
    error_message = "Expected 1 Linux VM"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["web"].name == "vm-web-01"
    error_message = "Expected Linux VM name to be vm-web-01"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["web"].size == "Standard_D2s_v3"
    error_message = "Expected VM size to be Standard_D2s_v3"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["web"].admin_username == "azureadmin"
    error_message = "Expected admin username to be azureadmin"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["web"].secure_boot_enabled == true
    error_message = "Expected secure boot to be enabled by default"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["web"].vtpm_enabled == true
    error_message = "Expected vTPM to be enabled by default"
  }
}

run "creates_windows_vm" {
  command = plan

  assert {
    condition     = length(azurerm_windows_virtual_machine.this) == 1
    error_message = "Expected 1 Windows VM"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.this["dc"].name == "vm-dc-01"
    error_message = "Expected Windows VM name to be vm-dc-01"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.this["dc"].size == "Standard_D4s_v3"
    error_message = "Expected VM size to be Standard_D4s_v3"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.this["dc"].secure_boot_enabled == true
    error_message = "Expected secure boot to be enabled by default"
  }
}

run "creates_network_interfaces" {
  command = plan

  assert {
    condition     = length(azurerm_network_interface.this) == 2
    error_message = "Expected 2 NICs (one per VM)"
  }

  assert {
    condition     = azurerm_network_interface.this["web"].name == "vm-web-01-nic"
    error_message = "Expected NIC name to be vm-web-01-nic"
  }

  assert {
    condition     = azurerm_network_interface.this["dc"].name == "vm-dc-01-nic"
    error_message = "Expected NIC name to be vm-dc-01-nic"
  }
}

run "creates_data_disks" {
  command = plan

  assert {
    condition     = length(azurerm_managed_disk.this) == 1
    error_message = "Expected 1 managed data disk"
  }

  assert {
    condition     = azurerm_managed_disk.this["dc-ntds"].name == "vm-dc-01-ntds"
    error_message = "Expected data disk name to be vm-dc-01-ntds"
  }

  assert {
    condition     = azurerm_managed_disk.this["dc-ntds"].disk_size_gb == 64
    error_message = "Expected data disk size to be 64 GB"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this["web"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["web"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}
