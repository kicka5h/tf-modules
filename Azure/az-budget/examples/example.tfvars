budgets = {
  # Dev environment — $500/month, single alert at 80%
  dev = {
    name              = "budget-dev-monthly"
    resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dev"
    amount            = 500
    time_grain        = "Monthly"
    time_period = {
      start_date = "2024-01-01T00:00:00Z"
    }
    notifications = {
      eighty_percent = {
        threshold      = 80
        contact_emails = ["dev-team@example.com"]
      }
    }
  }

  # Prod environment — $5000/month, alerts at 50%, 80%, 100%
  prod = {
    name              = "budget-prod-monthly"
    resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-prod"
    amount            = 5000
    time_grain        = "Monthly"
    time_period = {
      start_date = "2024-01-01T00:00:00Z"
    }
    notifications = {
      fifty_percent = {
        threshold      = 50
        threshold_type = "Forecasted"
        contact_emails = ["finops@example.com"]
      }
      eighty_percent = {
        threshold      = 80
        threshold_type = "Actual"
        contact_emails = ["finops@example.com", "eng-leads@example.com"]
        contact_groups = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.Insights/actionGroups/ag-ops-team"]
      }
      hundred_percent = {
        threshold      = 100
        threshold_type = "Actual"
        contact_emails = ["finops@example.com", "eng-leads@example.com", "vp-eng@example.com"]
        contact_roles  = ["Owner"]
        contact_groups = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.Insights/actionGroups/ag-ops-team"]
      }
    }
  }
}
