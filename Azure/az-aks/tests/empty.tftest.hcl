mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  aks_clusters        = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_kubernetes_cluster.this) == 0
    error_message = "Expected no AKS clusters with empty input"
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster_node_pool.this) == 0
    error_message = "Expected no additional node pools with empty input"
  }
}
