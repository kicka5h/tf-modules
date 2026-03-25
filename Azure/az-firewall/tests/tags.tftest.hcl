mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  firewalls = {
    test = {
      name = "fw-test"
      ip_configuration = {
        name                 = "ipconfig"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/AzureFirewallSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-fw-test"
      }
    }
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_firewall.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
  }

  assert {
    condition     = azurerm_firewall_policy.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag on policy"
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
    condition     = azurerm_firewall.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_firewall.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}
