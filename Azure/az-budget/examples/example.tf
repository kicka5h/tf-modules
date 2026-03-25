provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "dev" {
  name = "rg-dev"
}

data "azurerm_resource_group" "prod" {
  name = "rg-prod"
}

# Optional: reference an existing action group for prod alerts
data "azurerm_monitor_action_group" "ops" {
  resource_group_name = "rg-monitoring"
  name                = "ag-ops-team"
}

module "budgets" {
  source = "../"

  budgets = var.budgets

  tags = {
    Environment = "shared"
    ManagedBy   = "platform-team"
  }
}

output "budget_ids" {
  value = module.budgets.budgets
}
