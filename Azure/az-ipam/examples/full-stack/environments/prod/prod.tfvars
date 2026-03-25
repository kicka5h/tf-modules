resource_group_name = "rg-networking-prod"
location            = "eastus2"
environment         = "prod"

# IPAM: same shape as dev but different index — gets a different /16
# Prod gets larger subnets for AKS and app tiers
#
# Result:
#   prod environment: 10.3.0.0/16
#     hub VNet:        10.3.0.0/20
#       GatewaySubnet:   10.3.0.0/24
#       AzureFirewall:   10.3.1.0/24
#       management:      10.3.2.0/24
#       bastion:         10.3.3.0/24
#     spoke VNet:      10.3.64.0/18  (larger /18 for prod)
#       app:             10.3.64.0/20
#       data:            10.3.80.0/22
#       endpoints:       10.3.84.0/22
#       aks:             10.3.96.0/20

ipam_allocation = {
  cidr_newbits = 8
  cidr_index   = 3  # fourth /16 from /8
  vnets = {
    hub = {
      cidr_newbits = 4
      cidr_index   = 0
      subnets = {
        GatewaySubnet       = { cidr_newbits = 4, cidr_index = 0 }
        AzureFirewallSubnet = { cidr_newbits = 4, cidr_index = 1 }
        management          = { cidr_newbits = 4, cidr_index = 2 }
        AzureBastionSubnet  = { cidr_newbits = 4, cidr_index = 3 }
      }
    }
    spoke = {
      cidr_newbits = 2   # /18 instead of /20 — more room for prod
      cidr_index   = 1
      subnets = {
        app       = { cidr_newbits = 2, cidr_index = 0 }  # /20
        data      = { cidr_newbits = 4, cidr_index = 4 }  # /22
        endpoints = { cidr_newbits = 4, cidr_index = 5 }  # /22
        aks       = { cidr_newbits = 2, cidr_index = 2 }  # /20
      }
    }
  }
}

nsg_rules = {
  app = {
    allow_https = {
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTPS"
    }
    deny_all = {
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all inbound"
    }
  }
  data = {
    allow_sql_from_app = {
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "1433"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow SQL from app subnet"
    }
  }
  aks = {
    allow_https = {
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow ingress to AKS"
    }
  }
}

route_tables = {
  spoke_default = {
    bgp_route_propagation_enabled = false
    routes = {
      to_firewall = {
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.3.1.4"
      }
    }
    subnet_keys = ["app", "data", "endpoints", "aks"]
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
