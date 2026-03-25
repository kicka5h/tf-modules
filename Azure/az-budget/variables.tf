variable "budgets" {
  description = "Map of budgets to create. Key is a logical name."
  type = map(object({
    name              = string
    resource_group_id = string
    amount            = number
    time_grain        = optional(string, "Monthly") # "Monthly", "Quarterly", "Annually"
    time_period = object({
      start_date = string           # ISO 8601 format: "2024-01-01T00:00:00Z"
      end_date   = optional(string, null)
    })
    notifications = map(object({
      operator       = optional(string, "GreaterThanOrEqualTo")
      threshold      = number # percentage (e.g., 80 = 80%)
      threshold_type = optional(string, "Actual") # "Actual" or "Forecasted"
      contact_emails = optional(list(string), [])
      contact_roles  = optional(list(string), [])
      contact_groups = optional(list(string), []) # action group IDs
      enabled        = optional(bool, true)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, b in var.budgets : length(b.notifications) > 0
    ])
    error_message = "Every budget must have at least one notification threshold."
  }

  validation {
    condition = alltrue([
      for k, b in var.budgets : contains(["Monthly", "Quarterly", "Annually"], b.time_grain)
    ])
    error_message = "time_grain must be one of: Monthly, Quarterly, Annually."
  }

  validation {
    condition = alltrue(flatten([
      for k, b in var.budgets : [
        for nk, n in b.notifications : contains(["Actual", "Forecasted"], n.threshold_type)
      ]
    ]))
    error_message = "threshold_type must be one of: Actual, Forecasted."
  }

  validation {
    condition = alltrue(flatten([
      for k, b in var.budgets : [
        for nk, n in b.notifications : n.threshold > 0 && n.threshold <= 1000
      ]
    ]))
    error_message = "threshold must be between 1 and 1000 (percentage)."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
