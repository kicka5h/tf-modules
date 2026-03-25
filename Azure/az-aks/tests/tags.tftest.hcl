mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  aks_clusters = {
    test = {
      name       = "aks-test"
      dns_prefix = "akstest"
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

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this["test"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
  }
}

run "custom_tags_are_merged" {
  command = plan

  variables {
    tags = {
      environment = "dev"
    }
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["test"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this["test"].tags["environment"] == "dev"
    error_message = "Custom tag should be present"
  }
}
