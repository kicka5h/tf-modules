resource_group_name = "rg-network"
location            = "eastus2"

vnets = {
  hub = {
    name                    = "vnet-hub"
    address_space           = ["10.0.0.0/16"]
    dns_servers             = ["10.0.1.4", "10.0.1.5"]
    flow_timeout_in_minutes = 10
    ddos_protection_plan = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security/providers/Microsoft.Network/ddosProtectionPlans/ddos-plan"
      enable = true
    }
    subnets = {
      GatewaySubnet = {
        address_prefixes = ["10.0.1.0/24"]
      }
      AzureFirewallSubnet = {
        address_prefixes = ["10.0.2.0/24"]
      }
      management = {
        address_prefixes  = ["10.0.3.0/24"]
        service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      }
    }
  }

  spoke_app = {
    name          = "vnet-spoke-app"
    address_space = ["10.1.0.0/16"]
    encryption = {
      enforcement = "AllowUnencrypted"
    }
    subnets = {
      app = {
        address_prefixes = ["10.1.1.0/24"]
        delegation = {
          name = "app-service"
          service_delegation = {
            name    = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      }
      private_endpoints = {
        address_prefixes                  = ["10.1.2.0/24"]
        private_endpoint_network_policies = "Enabled"
      }
      data = {
        address_prefixes  = ["10.1.3.0/24"]
        service_endpoints = ["Microsoft.Sql"]
      }
    }
  }

  spoke_aks = {
    name          = "vnet-spoke-aks"
    address_space = ["10.2.0.0/16"]
    subnets = {
      nodes = {
        address_prefixes = ["10.2.0.0/20"]
      }
      pods = {
        address_prefixes = ["10.2.16.0/20"]
      }
      internal_lb = {
        address_prefixes = ["10.2.32.0/24"]
      }
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
