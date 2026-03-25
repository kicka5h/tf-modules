variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  private_endpoints   = {}
}

run "empty_endpoints" {
  command = plan

  assert {
    condition     = length(azurerm_private_endpoint.this) == 0
    error_message = "Expected no private endpoints when map is empty"
  }
}
