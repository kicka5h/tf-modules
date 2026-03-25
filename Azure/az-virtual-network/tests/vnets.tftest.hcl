mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  vnets = {
    hub = {
      name          = "vnet-hub"
      address_space = ["10.0.0.0/16"]
      subnets = {
        gateway = {
          address_prefixes = ["10.0.1.0/24"]
        }
        firewall = {
          address_prefixes  = ["10.0.2.0/24"]
          service_endpoints = ["Microsoft.Storage"]
        }
      }
    }
    spoke1 = {
      name          = "vnet-spoke1"
      address_space = ["10.1.0.0/16"]
      dns_servers   = ["10.0.1.4"]
      subnets = {
        workload = {
          address_prefixes = ["10.1.1.0/24"]
        }
        private_endpoints = {
          address_prefixes                  = ["10.1.2.0/24"]
          private_endpoint_network_policies = "Enabled"
        }
      }
    }
  }
}

run "creates_multiple_vnets" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_network.this) == 2
    error_message = "Expected 2 VNets"
  }

  assert {
    condition     = azurerm_virtual_network.this["hub"].name == "vnet-hub"
    error_message = "Expected hub VNet name to be vnet-hub"
  }

  assert {
    condition     = azurerm_virtual_network.this["spoke1"].name == "vnet-spoke1"
    error_message = "Expected spoke1 VNet name to be vnet-spoke1"
  }
}

run "creates_all_subnets" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 4
    error_message = "Expected 4 subnets across both VNets"
  }

  assert {
    condition     = azurerm_subnet.this["hub-gateway"].name == "gateway"
    error_message = "Expected subnet name to be gateway"
  }

  assert {
    condition     = azurerm_subnet.this["spoke1-private_endpoints"].private_endpoint_network_policies == "Enabled"
    error_message = "Expected private endpoint network policies to be Enabled"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this["hub"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_virtual_network.this["hub"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}

run "sets_dns_servers" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this["spoke1"].dns_servers == tolist(["10.0.1.4"])
    error_message = "Expected spoke1 DNS servers to be set"
  }

  assert {
    condition     = length(azurerm_virtual_network.this["hub"].dns_servers) == 0
    error_message = "Expected hub to have no custom DNS servers"
  }
}

run "sets_service_endpoints" {
  command = plan

  assert {
    condition     = tolist(azurerm_subnet.this["hub-firewall"].service_endpoints) == tolist(["Microsoft.Storage"])
    error_message = "Expected firewall subnet to have Microsoft.Storage service endpoint"
  }
}
