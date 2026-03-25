resource_group_name = "rg-network"
location            = "eastus2"

public_ips = {
  gateway = {
    name              = "pip-gateway"
    zones             = ["1", "2", "3"]
    domain_name_label = "myorg-gateway"
  }

  firewall = {
    name  = "pip-firewall"
    zones = ["1", "2", "3"]
  }

  app_lb = {
    name                    = "pip-app-lb"
    idle_timeout_in_minutes = 10
    domain_name_label       = "myorg-app"
    zones                   = ["1", "2", "3"]
  }

  bastion = {
    name = "pip-bastion"
  }

  nat_gateway = {
    name              = "pip-nat-gateway"
    zones             = ["1"]
    public_ip_prefix_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/publicIPPrefixes/ippre-nat"
  }
}

public_ip_prefixes = {
  nat = {
    name          = "ippre-nat"
    prefix_length = 30
    zones         = ["1"]
  }

  egress = {
    name          = "ippre-egress"
    prefix_length = 28
    zones         = ["1", "2", "3"]
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
