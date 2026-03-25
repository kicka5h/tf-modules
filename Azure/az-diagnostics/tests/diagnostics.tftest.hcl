mock_provider "azurerm" {}

variables {
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-test"

  diagnostic_settings = {
    vnet_with_categories = {
      name               = "diag-vnet"
      target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub"
      enabled_log_categories = [
        "VMProtectionAlerts",
      ]
      metric_categories = ["AllMetrics"]
    }
    nsg_defaults = {
      name               = "diag-nsg"
      target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
    }
  }
}

run "creates_both_diagnostic_settings" {
  command = plan

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.this) == 2
    error_message = "Expected 2 diagnostic settings"
  }
}

run "setting_with_specific_categories" {
  command = plan

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["vnet_with_categories"].name == "diag-vnet"
    error_message = "Expected diagnostic setting name to be diag-vnet"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["vnet_with_categories"].target_resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    error_message = "Expected target resource ID to match VNet"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["vnet_with_categories"].log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-test"
    error_message = "Expected log analytics workspace ID to match"
  }
}

run "setting_with_defaults_uses_all_logs" {
  command = plan

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["nsg_defaults"].name == "diag-nsg"
    error_message = "Expected diagnostic setting name to be diag-nsg"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["nsg_defaults"].target_resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
    error_message = "Expected target resource ID to match NSG"
  }
}

run "optional_destinations_default_to_null" {
  command = plan

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["nsg_defaults"].storage_account_id == null
    error_message = "Expected storage_account_id to be null when not provided"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["nsg_defaults"].eventhub_authorization_rule_id == null
    error_message = "Expected eventhub_authorization_rule_id to be null when not provided"
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.this["nsg_defaults"].eventhub_name == null
    error_message = "Expected eventhub_name to be null when not provided"
  }
}
