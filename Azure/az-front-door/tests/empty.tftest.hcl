mock_provider "azurerm" {}
mock_provider "http" {}

variables {
  resource_group_name = "rg-test"
  front_doors         = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_cdn_frontdoor_profile.this) == 0
    error_message = "Expected no Front Door profiles with empty input"
  }
}
