# az-diagnostics

Creates standardized Azure Monitor diagnostic settings for any Azure resource. Takes a map of resource IDs and a Log Analytics workspace ID, and creates `azurerm_monitor_diagnostic_setting` for each with consistent log categories and retention.

## Usage

```hcl
module "diagnostics" {
  source                     = "../az-diagnostics"
  log_analytics_workspace_id = module.log_analytics.id

  diagnostic_settings = {
    vnet = {
      name               = "diag-vnet-hub"
      target_resource_id = module.vnet.id
      enabled_log_categories = ["VMProtectionAlerts"]
    }
    nsg = {
      name               = "diag-nsg-web"
      target_resource_id = module.nsg.nsgs["web"].id
      # Omit enabled_log_categories to enable all available log categories
    }
    keyvault = {
      name               = "diag-kv"
      target_resource_id = module.keyvault.id
      enabled_log_categories = ["AuditEvent", "AzurePolicyEvaluationDetails"]
      storage_account_id     = module.storage.id  # also archive to storage
    }
  }
}
```

## Log Categories

Each diagnostic setting supports two modes for log collection:

- **All logs (default):** When `enabled_log_categories` is omitted or set to `[]`, the module uses the `allLogs` category group to automatically enable every available log category for the target resource. This is the recommended approach for most resources.
- **Specific categories:** When `enabled_log_categories` contains one or more category names, only those categories are enabled. Use this when you want to limit log volume or cost.

Common log categories by resource type:

| Resource Type | Example Categories |
| --- | --- |
| Virtual Network | `VMProtectionAlerts` |
| NSG | `NetworkSecurityGroupEvent`, `NetworkSecurityGroupRuleCounter` |
| Key Vault | `AuditEvent`, `AzurePolicyEvaluationDetails` |
| Storage Account | `StorageRead`, `StorageWrite`, `StorageDelete` |

## Metric Categories

By default, `AllMetrics` is enabled. You can override this per setting with the `metric_categories` field.

## Optional Destinations

In addition to the required Log Analytics workspace, each diagnostic setting can optionally send data to:

- **Storage Account** (`storage_account_id`) -- for long-term archival and compliance
- **Event Hub** (`eventhub_authorization_rule_id` + `eventhub_name`) -- for streaming to external SIEM or processing systems

## Wiring with Other Modules

This module is designed to consume resource IDs from other modules:

```hcl
module "vnet" {
  source = "../az-virtual-network"
  # ...
}

module "nsg" {
  source = "../az-nsg"
  # ...
}

module "diagnostics" {
  source                     = "../az-diagnostics"
  log_analytics_workspace_id = "/subscriptions/.../workspaces/law-central"

  diagnostic_settings = {
    vnet = {
      name               = "diag-vnet"
      target_resource_id = module.vnet.virtual_networks["hub"].id
    }
    nsg = {
      name               = "diag-nsg"
      target_resource_id = module.nsg.nsgs["web"].id
    }
  }
}
```

## Configuration Reference

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `log_analytics_workspace_id` | `string` | (required) | Log Analytics workspace ID |
| `diagnostic_settings` | `map(object)` | `{}` | Map of diagnostic settings to create |
| `diagnostic_settings.*.name` | `string` | (required) | Name of the diagnostic setting |
| `diagnostic_settings.*.target_resource_id` | `string` | (required) | Azure resource ID to monitor |
| `diagnostic_settings.*.enabled_log_categories` | `list(string)` | `[]` | Log categories; empty = all |
| `diagnostic_settings.*.metric_categories` | `list(string)` | `["AllMetrics"]` | Metric categories to enable |
| `diagnostic_settings.*.storage_account_id` | `string` | `null` | Storage account for archival |
| `diagnostic_settings.*.eventhub_authorization_rule_id` | `string` | `null` | Event Hub auth rule ID |
| `diagnostic_settings.*.eventhub_name` | `string` | `null` | Event Hub name |
