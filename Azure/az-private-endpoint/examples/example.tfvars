resource_group_name = "rg-private-endpoints"
location            = "eastus2"

private_endpoints = {
  storage_blob = {
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

  sql = {
    name      = "pe-sql"
    subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/private-endpoints"
    private_service_connection = {
      name                           = "psc-sql"
      private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data/providers/Microsoft.Sql/servers/sql-example"
      subresource_names              = ["sqlServer"]
    }
    private_dns_zone_group = {
      name                 = "default"
      private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"]
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
