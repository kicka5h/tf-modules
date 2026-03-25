mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  expressroute_circuits = {
    test = {
      name                  = "er-test"
      service_provider_name = "Equinix"
      peering_location      = "Silicon Valley"
      bandwidth_in_mbps     = 50
      sku = {
        tier   = "Standard"
        family = "MeteredData"
      }
    }
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_express_route_circuit.this["test"].tags["Terraform"] == "true"
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
    condition     = azurerm_express_route_circuit.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_express_route_circuit.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}
