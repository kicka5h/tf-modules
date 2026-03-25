variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
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
    keyvault = {
      name      = "pe-keyvault"
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/private-endpoints"
      private_service_connection = {
        name                           = "psc-keyvault"
        private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-example"
        subresource_names              = ["vault"]
      }
      private_dns_zone_group = {
        name                 = "default"
        private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
      }
    }
  }
}

run "multiple_endpoints" {
  command = plan

  assert {
    condition     = length(azurerm_private_endpoint.this) == 2
    error_message = "Expected two private endpoints"
  }

  assert {
    condition     = azurerm_private_endpoint.this["storage"].name == "pe-storage-blob"
    error_message = "Expected storage endpoint name to be pe-storage-blob"
  }

  assert {
    condition     = azurerm_private_endpoint.this["keyvault"].name == "pe-keyvault"
    error_message = "Expected keyvault endpoint name to be pe-keyvault"
  }
}
