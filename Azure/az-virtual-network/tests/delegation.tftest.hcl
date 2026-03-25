mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  vnets = {
    app = {
      name          = "vnet-app"
      address_space = ["10.2.0.0/16"]
      subnets = {
        aci = {
          address_prefixes = ["10.2.1.0/24"]
          delegation = {
            name = "aci-delegation"
            service_delegation = {
              name    = "Microsoft.ContainerInstance/containerGroups"
              actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
            }
          }
        }
        plain = {
          address_prefixes = ["10.2.2.0/24"]
        }
      }
    }
  }
}

run "creates_subnet_with_delegation" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected 2 subnets"
  }
}

run "subnet_without_delegation_has_none" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this["app-plain"].delegation) == 0
    error_message = "Expected plain subnet to have no delegation"
  }
}
