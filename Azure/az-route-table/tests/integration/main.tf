resource "azurerm_resource_group" "test" {
  name     = "rg-rt-integration-test"
  location = "eastus2"
}

module "route_tables" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  route_tables = {
    spoke = {
      name                          = "rt-spoke-test"
      bgp_route_propagation_enabled = false
      routes = {
        to_firewall = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.2.4"
        }
        to_vnet = {
          address_prefix = "10.0.0.0/8"
          next_hop_type  = "VnetLocal"
        }
      }
    }
  }

  tags = { environment = "integration-test" }
}

output "route_table_id" {
  value = module.route_tables.route_tables["spoke"].id
}

output "route_count" {
  value = length(module.route_tables.routes)
}
