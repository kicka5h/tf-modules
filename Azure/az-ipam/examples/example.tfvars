# Organization-wide address space
root_cidrs = ["10.0.0.0/8"]

# Existing allocations discovered by scripts/discover-ip-allocations.sh
# Run: ./scripts/discover-ip-allocations.sh --tfvars > reserved.auto.tfvars
# These would normally come from the generated file, shown inline for the example.
reserved_cidrs = [
  "10.100.0.0/16",  # legacy datacenter VNet
  "10.200.0.0/16",  # partner VPN range
  "172.16.0.0/12",  # on-premises network
]

# IP allocation plan
#
# Address space layout (from 10.0.0.0/8):
#   10.0.0.0/16  = dev
#   10.1.0.0/16  = qa
#   10.2.0.0/16  = stage
#   10.3.0.0/16  = prod
#
# Each environment subdivides into VNets:
#   x.x.0.0/20   = hub  (gateway, firewall, management, bastion)
#   x.x.16.0/20  = spoke-app (app, data, endpoints, aks)
#   x.x.32.0/20  = spoke-data (databases, caches, analytics)

allocations = {
  dev = {
    cidr_newbits = 8    # /16 from /8
    cidr_index   = 0    # 10.0.0.0/16
    vnets = {
      hub = {
        cidr_newbits = 4  # /20 from /16
        cidr_index   = 0  # 10.0.0.0/20
        subnets = {
          GatewaySubnet       = { cidr_newbits = 4, cidr_index = 0 }  # 10.0.0.0/24
          AzureFirewallSubnet = { cidr_newbits = 4, cidr_index = 1 }  # 10.0.1.0/24
          management          = { cidr_newbits = 4, cidr_index = 2 }  # 10.0.2.0/24
          AzureBastionSubnet  = { cidr_newbits = 4, cidr_index = 3 }  # 10.0.3.0/24
        }
      }
      spoke_app = {
        cidr_newbits = 4  # /20 from /16
        cidr_index   = 1  # 10.0.16.0/20
        subnets = {
          app       = { cidr_newbits = 2, cidr_index = 0 }  # 10.0.16.0/22
          data      = { cidr_newbits = 4, cidr_index = 2 }  # 10.0.18.0/24 (within /22 gap)
          endpoints = { cidr_newbits = 4, cidr_index = 3 }  # 10.0.19.0/24
        }
      }
      spoke_data = {
        cidr_newbits = 4  # /20 from /16
        cidr_index   = 2  # 10.0.32.0/20
        subnets = {
          databases = { cidr_newbits = 4, cidr_index = 0 }  # 10.0.32.0/24
          caches    = { cidr_newbits = 4, cidr_index = 1 }  # 10.0.33.0/24
          analytics = { cidr_newbits = 2, cidr_index = 1 }  # 10.0.36.0/22
        }
      }
    }
  }

  qa = {
    cidr_newbits = 8
    cidr_index   = 1    # 10.1.0.0/16
    vnets = {
      hub = {
        cidr_newbits = 4
        cidr_index   = 0
        subnets = {
          GatewaySubnet       = { cidr_newbits = 4, cidr_index = 0 }
          AzureFirewallSubnet = { cidr_newbits = 4, cidr_index = 1 }
          management          = { cidr_newbits = 4, cidr_index = 2 }
        }
      }
      spoke_app = {
        cidr_newbits = 4
        cidr_index   = 1
        subnets = {
          app       = { cidr_newbits = 2, cidr_index = 0 }
          data      = { cidr_newbits = 4, cidr_index = 2 }
          endpoints = { cidr_newbits = 4, cidr_index = 3 }
        }
      }
    }
  }

  stage = {
    cidr_newbits = 8
    cidr_index   = 2    # 10.2.0.0/16
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
      spoke_app = {
        cidr_newbits = 4
        cidr_index   = 1
        subnets = {
          app       = { cidr_newbits = 2, cidr_index = 0 }
          data      = { cidr_newbits = 4, cidr_index = 2 }
          endpoints = { cidr_newbits = 4, cidr_index = 3 }
          aks       = { cidr_newbits = 2, cidr_index = 1 }
        }
      }
    }
  }

  prod = {
    cidr_newbits = 8
    cidr_index   = 3    # 10.3.0.0/16
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
      spoke_app = {
        cidr_newbits = 2
        cidr_index   = 1  # /18 — larger for prod
        subnets = {
          app       = { cidr_newbits = 2, cidr_index = 0 }  # /20
          data      = { cidr_newbits = 4, cidr_index = 2 }  # /22
          endpoints = { cidr_newbits = 4, cidr_index = 3 }  # /22
          aks       = { cidr_newbits = 2, cidr_index = 1 }  # /20
        }
      }
      spoke_data = {
        cidr_newbits = 2
        cidr_index   = 2  # /18
        subnets = {
          databases = { cidr_newbits = 4, cidr_index = 0 }  # /22
          caches    = { cidr_newbits = 4, cidr_index = 1 }  # /22
          analytics = { cidr_newbits = 2, cidr_index = 1 }  # /20
        }
      }
    }
  }
}
