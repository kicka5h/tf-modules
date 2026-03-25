mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  nat_gateways = {
    egress = {
      name = "natgw-egress"
      public_ip_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/publicIPAddresses/pip-natgw-1",
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/publicIPAddresses/pip-natgw-2",
      ]
      subnet_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/workload",
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/data",
      ]
    }
    shared = {
      name = "natgw-shared"
      public_ip_prefix_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/publicIPPrefixes/pipp-natgw",
      ]
    }
  }
}

run "creates_public_ip_associations" {
  command = plan

  assert {
    condition     = length(azurerm_nat_gateway_public_ip_association.this) == 2
    error_message = "Expected 2 public IP associations"
  }
}

run "creates_public_ip_prefix_associations" {
  command = plan

  assert {
    condition     = length(azurerm_nat_gateway_public_ip_prefix_association.this) == 1
    error_message = "Expected 1 public IP prefix association"
  }
}

run "creates_subnet_associations" {
  command = plan

  assert {
    condition     = length(azurerm_subnet_nat_gateway_association.this) == 2
    error_message = "Expected 2 subnet associations"
  }
}
