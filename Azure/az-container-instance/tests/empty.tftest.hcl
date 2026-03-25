variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  container_groups    = {}
}

run "empty_container_groups" {
  command = plan

  assert {
    condition     = length(azurerm_container_group.this) == 0
    error_message = "Expected no container groups when container_groups is empty."
  }
}
