mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  load_balancers = {
    test = {
      name = "lb-test"
      frontend_ip_configurations = {
        primary = {
          name                 = "fe-primary"
          public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/publicIPAddresses/pip-lb"
        }
      }
    }
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_lb.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
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
    condition     = azurerm_lb.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_lb.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}
