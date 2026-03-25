variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  scale_sets = {
    bad = {
      name           = "vmss-bad"
      os_type        = "freebsd"
      sku            = "Standard_D2s_v5"
      admin_username = "azureadmin"
      admin_password = "P@ssw0rd1234!"
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
      network_interface = {
        name      = "nic-bad"
        subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-bad"
      }
    }
  }
}

run "reject_invalid_os_type" {
  command = plan

  expect_failures = [
    var.scale_sets,
  ]
}
