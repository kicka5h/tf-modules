variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID to send diagnostics to"
  type        = string
}

variable "diagnostic_settings" {
  description = "Map of diagnostic settings to create. Key is a logical name."
  type = map(object({
    name               = string
    target_resource_id = string
    # Log categories to enable — if empty, all available categories are enabled
    enabled_log_categories = optional(list(string), [])
    # Metric categories to enable
    metric_categories = optional(list(string), ["AllMetrics"])
    # Optional: also send to storage account for long-term retention
    storage_account_id = optional(string, null)
    # Optional: also send to event hub
    eventhub_authorization_rule_id = optional(string, null)
    eventhub_name                  = optional(string, null)
  }))
  default = {}
}
