resource_group_name = "rg-network"
location            = "eastus2"

nat_gateways = {
  egress = {
    name                    = "natgw-egress"
    idle_timeout_in_minutes = 10
    zones                   = ["1", "2"]
    public_ip_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/publicIPAddresses/pip-natgw-egress-1",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/publicIPAddresses/pip-natgw-egress-2",
    ]
    subnet_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/workload",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/data",
    ]
  }

  shared = {
    name = "natgw-shared"
    public_ip_prefix_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/publicIPPrefixes/pipp-natgw-shared",
    ]
    subnet_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-shared/subnets/app",
    ]
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
