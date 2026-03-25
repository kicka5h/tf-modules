mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  public_ips          = {}
  public_ip_prefixes  = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_public_ip.this) == 0
    error_message = "Expected no public IPs with empty input"
  }

  assert {
    condition     = length(azurerm_public_ip_prefix.this) == 0
    error_message = "Expected no public IP prefixes with empty input"
  }
}
