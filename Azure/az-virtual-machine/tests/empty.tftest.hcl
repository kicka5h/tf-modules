mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  virtual_machines    = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_network_interface.this) == 0
    error_message = "Expected no NICs with empty input"
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.this) == 0
    error_message = "Expected no Linux VMs with empty input"
  }

  assert {
    condition     = length(azurerm_windows_virtual_machine.this) == 0
    error_message = "Expected no Windows VMs with empty input"
  }

  assert {
    condition     = length(azurerm_managed_disk.this) == 0
    error_message = "Expected no managed disks with empty input"
  }
}
