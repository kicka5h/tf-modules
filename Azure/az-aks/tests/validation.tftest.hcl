mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
}

run "rejects_rbac_disabled" {
  command = plan

  variables {
    aks_clusters = {
      bad = {
        name                              = "aks-bad"
        dns_prefix                        = "aksbad"
        role_based_access_control_enabled = false
        default_node_pool = {
          name           = "system"
          vm_size        = "Standard_D4s_v5"
          min_count      = 1
          max_count      = 3
          vnet_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/system"
        }
      }
    }
  }

  expect_failures = [var.aks_clusters]
}

run "rejects_invalid_sku_tier" {
  command = plan

  variables {
    aks_clusters = {
      bad = {
        name       = "aks-bad"
        dns_prefix = "aksbad"
        sku_tier   = "InvalidTier"
        default_node_pool = {
          name           = "system"
          vm_size        = "Standard_D4s_v5"
          min_count      = 1
          max_count      = 3
          vnet_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/system"
        }
      }
    }
  }

  expect_failures = [var.aks_clusters]
}
