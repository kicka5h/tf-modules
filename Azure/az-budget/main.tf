locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_consumption_budget_resource_group" "this" {
  for_each = var.budgets

  name              = each.value.name
  resource_group_id = each.value.resource_group_id
  amount            = each.value.amount
  time_grain        = each.value.time_grain

  time_period {
    start_date = each.value.time_period.start_date
    end_date   = each.value.time_period.end_date
  }

  dynamic "notification" {
    for_each = each.value.notifications
    content {
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      contact_roles  = notification.value.contact_roles
      contact_groups = notification.value.contact_groups
      enabled        = notification.value.enabled
    }
  }
}
