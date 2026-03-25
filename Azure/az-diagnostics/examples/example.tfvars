log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-central"

diagnostic_settings = {
  vnet_hub = {
    name               = "diag-vnet-hub"
    target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    enabled_log_categories = [
      "VMProtectionAlerts",
    ]
    metric_categories = ["AllMetrics"]
  }

  nsg_web = {
    name               = "diag-nsg-web"
    target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
    # Empty enabled_log_categories — all available log categories will be enabled
  }

  keyvault = {
    name               = "diag-kv-secrets"
    target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-secrets"
    enabled_log_categories = [
      "AuditEvent",
      "AzurePolicyEvaluationDetails",
    ]
    storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/stdiagarchive"
  }

  storage_account = {
    name               = "diag-st-data"
    target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-data/providers/Microsoft.Storage/storageAccounts/stdata"
    metric_categories  = ["Transaction", "Capacity"]
    eventhub_authorization_rule_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-evhub/providers/Microsoft.EventHub/namespaces/evhns-central/authorizationRules/DiagSend"
    eventhub_name = "diagnostics"
  }
}
