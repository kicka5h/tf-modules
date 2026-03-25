mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  virtual_machines = {
    bad = {
      name           = "vm-bad"
      os_type        = "freebsd"
      size           = "Standard_D2s_v3"
      admin_username = "azureadmin"
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/web"
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
    }
  }
}

run "rejects_invalid_os_type" {
  command         = plan
  expect_failures = [var.virtual_machines]
}
