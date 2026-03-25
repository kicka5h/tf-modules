resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  eventhub_name                  = each.value.eventhub_name

  # When enabled_log_categories is specified, create one block per category
  dynamic "enabled_log" {
    for_each = length(each.value.enabled_log_categories) > 0 ? each.value.enabled_log_categories : []
    content {
      category = enabled_log.value
    }
  }

  # When enabled_log_categories is empty, enable all via category_group
  dynamic "enabled_log" {
    for_each = length(each.value.enabled_log_categories) == 0 ? ["allLogs"] : []
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
  }
}
