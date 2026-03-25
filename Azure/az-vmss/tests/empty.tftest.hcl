variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  scale_sets          = {}
}

run "empty_scale_sets" {
  command = plan

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this) == 0
    error_message = "Expected no Linux VMSS resources when scale_sets is empty."
  }

  assert {
    condition     = length(azurerm_windows_virtual_machine_scale_set.this) == 0
    error_message = "Expected no Windows VMSS resources when scale_sets is empty."
  }
}
