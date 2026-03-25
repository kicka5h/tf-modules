mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  route_tables = {
    spoke = {
      name = "rt-spoke"
      routes = {
        default = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.2.4"
        }
      }
      subnet_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/workload",
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/data",
      ]
    }
  }
}

run "creates_subnet_associations" {
  command = plan

  assert {
    condition     = length(azurerm_subnet_route_table_association.this) == 2
    error_message = "Expected 2 subnet associations"
  }
}
