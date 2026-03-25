package terraform.cost.premium_sku

import rego.v1

# Restrict premium/expensive SKUs in non-production environments.

is_nonprod if {
  env := input.variables.environment.value
  env in {"dev", "qa"}
}

is_nonprod if {
  tags := input.planned_values.root_module.resources[_].values.tags
  tags.environment in {"dev", "qa"}
}

# Firewall: reject Premium tier in non-prod
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_firewall"
  "create" in rc.change.actions
  rc.change.after.sku_tier == "Premium"
  msg := sprintf(
    "Cost policy: Firewall '%s' uses Premium tier in non-production. Use Standard instead.",
    [rc.address],
  )
}

# App Service Plan: reject P-series (Premium v3) in non-prod
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_service_plan"
  "create" in rc.change.actions
  sku := rc.change.after.sku_name
  startswith(sku, "P")
  msg := sprintf(
    "Cost policy: App Service Plan '%s' uses Premium SKU '%s' in non-production. Use S1 or B1 instead.",
    [rc.address, sku],
  )
}

# AKS: reject Premium tier in non-prod
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster"
  "create" in rc.change.actions
  rc.change.after.sku_tier == "Premium"
  msg := sprintf(
    "Cost policy: AKS cluster '%s' uses Premium tier in non-production. Use Standard or Free instead.",
    [rc.address],
  )
}

# Front Door: reject Premium in non-prod
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_cdn_frontdoor_profile"
  "create" in rc.change.actions
  rc.change.after.sku_name == "Premium_AzureFrontDoor"
  msg := sprintf(
    "Cost policy: Front Door '%s' uses Premium SKU in non-production. Use Standard_AzureFrontDoor instead.",
    [rc.address],
  )
}

# Application Gateway: reject WAF_v2 in non-prod (Standard_v2 is sufficient for testing)
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_application_gateway"
  "create" in rc.change.actions
  some sku in rc.change.after.sku
  sku.name == "WAF_v2"
  msg := sprintf(
    "Cost policy: Application Gateway '%s' uses WAF_v2 in non-production. Use Standard_v2 instead.",
    [rc.address],
  )
}
