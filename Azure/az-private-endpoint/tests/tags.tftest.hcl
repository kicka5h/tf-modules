variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  tags = {
    environment = "test"
    team        = "platform"
  }
  private_endpoints = {
    storage = {
      name      = "pe-storage-blob"
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/private-endpoints"
      private_service_connection = {
        name                           = "psc-storage-blob"
        private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data/providers/Microsoft.Storage/storageAccounts/stexample"
        subresource_names              = ["blob"]
      }
      private_dns_zone_group = {
        name                 = "default"
        private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
      }
    }
  }
}

run "tags_merged" {
  command = plan

  assert {
    condition     = azurerm_private_endpoint.this["storage"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag"
  }

  assert {
    condition     = azurerm_private_endpoint.this["storage"].tags["environment"] == "test"
    error_message = "Expected custom environment tag"
  }

  assert {
    condition     = azurerm_private_endpoint.this["storage"].tags["team"] == "platform"
    error_message = "Expected custom team tag"
  }
}
