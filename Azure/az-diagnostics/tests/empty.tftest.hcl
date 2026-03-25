mock_provider "azurerm" {}

variables {
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-test"
  diagnostic_settings        = {}
}

run "no_resources_created_with_empty_input" {
  command = plan

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.this) == 0
    error_message = "Expected no diagnostic settings with empty input"
  }
}
