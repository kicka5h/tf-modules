resource_group_name = "rg-network"
location            = "eastus2"

route_tables = {
  spoke_default = {
    name                          = "rt-spoke-default"
    bgp_route_propagation_enabled = false
    routes = {
      to_internet = {
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.2.4"
      }
      to_onprem = {
        address_prefix = "172.16.0.0/12"
        next_hop_type  = "VirtualNetworkGateway"
      }
      to_shared_services = {
        address_prefix         = "10.10.0.0/16"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.2.4"
      }
    }
    subnet_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/workload",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/data",
    ]
  }

  hub_gateway = {
    name = "rt-hub-gateway"
    routes = {
      to_spoke = {
        address_prefix         = "10.1.0.0/16"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.2.4"
      }
    }
    subnet_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/GatewaySubnet",
    ]
  }

  isolated = {
    name = "rt-isolated"
    routes = {
      blackhole = {
        address_prefix = "0.0.0.0/0"
        next_hop_type  = "None"
      }
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
