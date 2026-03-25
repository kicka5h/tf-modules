mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  aks_clusters = {
    prod = {
      name                    = "aks-prod"
      dns_prefix              = "aksprod"
      sku_tier                = "Standard"
      private_cluster_enabled = true
      default_node_pool = {
        name           = "system"
        vm_size        = "Standard_D4s_v5"
        min_count      = 2
        max_count      = 5
        vnet_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/system"
      }
      additional_node_pools = {
        workload = {
          name           = "workload"
          vm_size        = "Standard_D8s_v5"
          min_count      = 1
          max_count      = 10
          vnet_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/workload"
          mode           = "User"
          node_labels = {
            workload = "general"
          }
        }
      }
    }
  }
}

run "creates_cluster" {
  command = plan

  assert {
    condition     = length(azurerm_kubernetes_cluster.this) == 1
    error_message = "Expected 1 AKS cluster"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].name == "aks-prod"
    error_message = "Expected cluster name to be aks-prod"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].dns_prefix == "aksprod"
    error_message = "Expected dns_prefix to be aksprod"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].sku_tier == "Standard"
    error_message = "Expected sku_tier to be Standard"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].private_cluster_enabled == true
    error_message = "Expected private_cluster_enabled to be true"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].role_based_access_control_enabled == true
    error_message = "Expected RBAC to be enabled"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].automatic_upgrade_channel == "stable"
    error_message = "Expected automatic_upgrade_channel to be stable"
  }
}

run "creates_additional_node_pool" {
  command = plan

  assert {
    condition     = length(azurerm_kubernetes_cluster_node_pool.this) == 1
    error_message = "Expected 1 additional node pool"
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.this["prod-workload"].name == "workload"
    error_message = "Expected node pool name to be workload"
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.this["prod-workload"].vm_size == "Standard_D8s_v5"
    error_message = "Expected node pool vm_size to be Standard_D8s_v5"
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.this["prod-workload"].mode == "User"
    error_message = "Expected node pool mode to be User"
  }
}

run "sets_location_and_resource_group" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].location == "eastus2"
    error_message = "Expected location to be eastus2"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["prod"].resource_group_name == "rg-test"
    error_message = "Expected resource group to be rg-test"
  }
}
