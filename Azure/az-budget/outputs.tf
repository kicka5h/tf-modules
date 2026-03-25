output "budgets" {
  description = "Map of budgets created, keyed by the logical name"
  value = {
    for k, v in azurerm_consumption_budget_resource_group.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
