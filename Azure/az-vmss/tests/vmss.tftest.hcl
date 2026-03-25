variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  scale_sets = {
    web = {
      name           = "vmss-web"
      os_type        = "linux"
      sku            = "Standard_D2s_v5"
      instances      = 2
      zones          = ["1", "2", "3"]
      admin_username = "azureadmin"
      admin_ssh_key = {
        public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7test..."
      }
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
      network_interface = {
        name      = "nic-web"
        subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-web"
      }
    }
  }
}

run "linux_vmss_plan" {
  command = plan

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this) == 1
    error_message = "Expected exactly one Linux VMSS resource."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].name == "vmss-web"
    error_message = "Expected VMSS name to be vmss-web."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].sku == "Standard_D2s_v5"
    error_message = "Expected VMSS SKU to be Standard_D2s_v5."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].instances == 2
    error_message = "Expected 2 instances."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].secure_boot_enabled == true
    error_message = "Expected secure boot to be enabled by default."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].vtpm_enabled == true
    error_message = "Expected vTPM to be enabled by default."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].zone_balance == true
    error_message = "Expected zone balancing to be enabled by default."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].upgrade_mode == "Rolling"
    error_message = "Expected upgrade mode to be Rolling by default."
  }

  assert {
    condition     = length(azurerm_windows_virtual_machine_scale_set.this) == 0
    error_message = "Expected no Windows VMSS resources."
  }
}
