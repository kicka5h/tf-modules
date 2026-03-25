# az-budget

Creates and manages Azure Consumption Budgets for resource groups with configurable alert thresholds and action group integration. Enforces that every resource group has cost controls by requiring at least one notification per budget.

## Usage

```hcl
module "budgets" {
  source = "../az-budget"

  budgets = {
    prod = {
      name              = "budget-prod-monthly"
      resource_group_id = azurerm_resource_group.prod.id
      amount            = 5000
      time_grain        = "Monthly"
      time_period = {
        start_date = "2024-01-01T00:00:00Z"
      }
      notifications = {
        eighty_percent = {
          threshold      = 80
          contact_emails = ["finops@example.com"]
        }
        hundred_percent = {
          threshold      = 100
          contact_emails = ["finops@example.com", "eng-leads@example.com"]
          contact_roles  = ["Owner"]
          contact_groups = [azurerm_monitor_action_group.ops.id]
        }
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Configuration Reference

### Budgets

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | required | Display name of the budget |
| `resource_group_id` | `string` | required | Resource group ID to scope the budget to |
| `amount` | `number` | required | Budget amount in the subscription's billing currency |
| `time_grain` | `string` | `"Monthly"` | `"Monthly"`, `"Quarterly"`, or `"Annually"` |
| `time_period.start_date` | `string` | required | ISO 8601 start date (e.g., `"2024-01-01T00:00:00Z"`) |
| `time_period.end_date` | `string` | `null` | ISO 8601 end date (optional, defaults to 10 years from start) |

### Notifications

Each budget must have at least one notification (enforced by validation).

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `threshold` | `number` | required | Percentage threshold (e.g., `80` = 80%) |
| `threshold_type` | `string` | `"Actual"` | `"Actual"` (already spent) or `"Forecasted"` (predicted) |
| `operator` | `string` | `"GreaterThanOrEqualTo"` | Comparison operator |
| `contact_emails` | `list(string)` | `[]` | Email addresses to notify |
| `contact_roles` | `list(string)` | `[]` | Azure RBAC roles to notify (e.g., `"Owner"`) |
| `contact_groups` | `list(string)` | `[]` | Action group resource IDs |
| `enabled` | `bool` | `true` | Whether this notification is active |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |

## Recommended Thresholds by Environment

| Environment | Amount | Thresholds | Notes |
| --- | --- | --- | --- |
| **Dev/Sandbox** | $200--$500 | 80% Actual | Single alert is usually enough; catches runaway resources |
| **Staging** | $500--$2000 | 80% Actual, 100% Actual | Mirror prod structure at lower amounts |
| **Production** | $2000--$10000+ | 50% Forecasted, 80% Actual, 100% Actual | Early forecasted warning gives time to react |
| **Shared/Platform** | Varies | 50% Forecasted, 80% Actual, 100% Actual, 120% Actual | Include overage alert for shared services |

## Wiring with Action Groups

Action groups let you trigger automation (webhooks, Logic Apps, Azure Functions) in addition to email notifications. Pass the action group resource ID to `contact_groups`:

```hcl
# Create or reference an action group
resource "azurerm_monitor_action_group" "cost_alerts" {
  name                = "ag-cost-alerts"
  resource_group_name = "rg-monitoring"
  short_name          = "CostAlert"

  email_receiver {
    name          = "finops"
    email_address = "finops@example.com"
  }

  webhook_receiver {
    name        = "slack-webhook"
    service_uri = "https://hooks.slack.com/services/XXX/YYY/ZZZ"
  }
}

# Reference it in the budget
module "budgets" {
  source = "../az-budget"

  budgets = {
    prod = {
      name              = "budget-prod"
      resource_group_id = azurerm_resource_group.prod.id
      amount            = 5000
      time_period = {
        start_date = "2024-01-01T00:00:00Z"
      }
      notifications = {
        critical = {
          threshold      = 100
          contact_groups = [azurerm_monitor_action_group.cost_alerts.id]
        }
      }
    }
  }
}
```

## Enforced Policies

- **At least one notification**: Every budget must define at least one notification threshold. Rejected at plan time otherwise.
- **Valid time grain**: Must be `"Monthly"`, `"Quarterly"`, or `"Annually"`.
- **Valid threshold type**: Must be `"Actual"` or `"Forecasted"`.
- **Threshold range**: Must be between 1 and 1000.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
