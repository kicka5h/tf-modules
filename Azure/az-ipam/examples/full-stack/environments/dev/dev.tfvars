resource_group_name = "rg-networking-dev"
location            = "eastus2"
environment         = "dev"

# IPAM: just define the shape, not the addresses
# Addresses are calculated automatically from the root CIDR (10.0.0.0/8)
#
# Result:
#   dev environment: 10.0.0.0/16
#     hub VNet:        10.0.0.0/20
#       GatewaySubnet:   10.0.0.0/24
#       AzureFirewall:   10.0.1.0/24
#       management:      10.0.2.0/24
#       bastion:         10.0.3.0/24
#     spoke VNet:      10.0.16.0/20
#       app:             10.0.16.0/22
#       data:            10.0.20.0/24
#       endpoints:       10.0.21.0/24
#       aks:             10.0.24.0/22

ipam_allocation = {
  cidr_newbits = 8
  cidr_index   = 0  # first /16 from /8
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
      cidr_newbits = 4
      cidr_index   = 1
      subnets = {
        app       = { cidr_newbits = 2, cidr_index = 0 }
        data      = { cidr_newbits = 4, cidr_index = 4 }
        endpoints = { cidr_newbits = 4, cidr_index = 5 }
        aks       = { cidr_newbits = 2, cidr_index = 2 }
      }
    }
  }
}

# NSG rules — reference subnet names from the IPAM allocation
# Addresses are never hardcoded
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
}

# Route tables — reference subnet names for auto-association
route_tables = {
  spoke_default = {
    bgp_route_propagation_enabled = false
    routes = {
      to_firewall = {
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.0.1.4"
      }
    }
    subnet_keys = ["app", "data", "endpoints"]
  }
}

tags = {
  environment = "dev"
  managed_by  = "terraform"
}
