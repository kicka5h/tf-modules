run "reject_budget_with_no_notifications" {
  command = plan

  variables {
    budgets = {
      bad = {
        name              = "budget-bad"
        resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bad"
        amount            = 100
        time_period = {
          start_date = "2024-01-01T00:00:00Z"
        }
        notifications = {}
      }
    }
  }

  expect_failures = [
    var.budgets,
  ]
}
