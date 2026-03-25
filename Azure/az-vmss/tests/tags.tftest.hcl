variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  scale_sets = {
    web = {
      name           = "vmss-web"
      os_type        = "linux"
      sku            = "Standard_D2s_v5"
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
      tags = {
        Role = "web"
      }
    }
  }

  tags = {
    Environment = "test"
  }
}

run "tags_merged" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag to be present."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].tags["Environment"] == "test"
    error_message = "Expected module-level tags to be merged."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this["web"].tags["Role"] == "web"
    error_message = "Expected per-scale-set tags to be merged."
  }
}
