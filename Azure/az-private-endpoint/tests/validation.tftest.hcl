variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  private_endpoints = {
    missing_dns = {
      name      = "pe-no-dns"
      subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-spoke/subnets/private-endpoints"
      private_service_connection = {
        name                           = "psc-no-dns"
        private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data/providers/Microsoft.Storage/storageAccounts/stexample"
        subresource_names              = ["blob"]
      }
      # private_dns_zone_group intentionally omitted to test validation
    }
  }
}

run "reject_missing_dns_zone_group" {
  command = plan

  expect_failures = [
    var.private_endpoints,
  ]
}
