resource_group_name = "rg-containers"
location            = "eastus2"

container_registries = {
  main = {
    name                          = "crproductionmain"
    sku                           = "Premium"
    admin_enabled                 = false
    zone_redundancy_enabled       = true
    public_network_access_enabled = false
    network_rule_bypass_option    = "AzureServices"
    trust_policy_enabled          = true

    retention_policy = {
      days    = 30
      enabled = true
    }

    georeplications = {
      westus2 = {
        location                = "westus2"
        zone_redundancy_enabled = true
        tags = {
          region = "westus2"
        }
      }
      northeurope = {
        location                = "northeurope"
        zone_redundancy_enabled = true
        tags = {
          region = "northeurope"
        }
      }
    }

    identity = {
      type = "SystemAssigned"
    }

    tags = {
      application = "platform"
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
