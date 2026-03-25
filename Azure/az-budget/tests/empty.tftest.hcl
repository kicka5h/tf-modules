run "empty_budgets" {
  command = plan

  variables {
    budgets = {}
  }

  assert {
    condition     = length(keys(azurerm_consumption_budget_resource_group.this)) == 0
    error_message = "Expected no budgets when input is empty."
  }
}
