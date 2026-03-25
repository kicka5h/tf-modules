mock_provider "azurerm" {}

run "budget_with_two_notifications" {
  command = plan

  variables {
    budgets = {
      dev = {
        name              = "budget-dev"
        resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dev"
        amount            = 500
        time_grain        = "Monthly"
        time_period = {
          start_date = "2024-01-01T00:00:00Z"
        }
        notifications = {
          eighty_percent = {
            threshold      = 80
            threshold_type = "Actual"
            contact_emails = ["team@example.com"]
          }
          hundred_percent = {
            threshold      = 100
            threshold_type = "Actual"
            contact_emails = ["team@example.com", "manager@example.com"]
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_consumption_budget_resource_group.this["dev"].name == "budget-dev"
    error_message = "Budget name should be budget-dev."
  }

  assert {
    condition     = azurerm_consumption_budget_resource_group.this["dev"].amount == 500
    error_message = "Budget amount should be 500."
  }

  assert {
    condition     = azurerm_consumption_budget_resource_group.this["dev"].time_grain == "Monthly"
    error_message = "Budget time grain should be Monthly."
  }
}
