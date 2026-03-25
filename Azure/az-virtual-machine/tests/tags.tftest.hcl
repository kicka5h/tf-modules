mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  virtual_machines = {
    test = {
      name           = "vm-test-01"
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
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
  }

  assert {
    condition     = azurerm_network_interface.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag on NIC"
  }
}

run "custom_tags_are_merged" {
  command = plan

  variables {
    tags = {
      environment = "dev"
    }
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}

run "per_vm_tags_are_merged" {
  command = plan

  variables {
    tags = {
      environment = "dev"
    }
    virtual_machines = {
      test = {
        name           = "vm-test-01"
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
        tags = {
          role = "webserver"
        }
      }
    }
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["test"].tags["environment"] == "dev"
    error_message = "Module-level tag should be present"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this["test"].tags["role"] == "webserver"
    error_message = "Per-VM tag should be present"
  }
}
