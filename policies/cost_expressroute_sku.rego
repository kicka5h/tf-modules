package terraform.cost.expressroute_sku

import rego.v1

# Restrict ExpressRoute SKU in non-production environments.
# Premium tier is significantly more expensive than Standard.
# UnlimitedData is significantly more expensive than MeteredData.

is_nonprod if {
  env := input.variables.environment.value
  env in {"dev", "qa"}
}

is_nonprod if {
  tags := input.planned_values.root_module.resources[_].values.tags
  tags.environment in {"dev", "qa"}
}

deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_express_route_circuit"
  "create" in rc.change.actions
  some sku in rc.change.after.sku
  sku.tier == "Premium"
  msg := sprintf(
    "Cost policy: ExpressRoute circuit '%s' uses Premium tier in non-production. Use Standard instead.",
    [rc.address],
  )
}

deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_express_route_circuit"
  "create" in rc.change.actions
  some sku in rc.change.after.sku
  sku.family == "UnlimitedData"
  msg := sprintf(
    "Cost policy: ExpressRoute circuit '%s' uses UnlimitedData in non-production. Use MeteredData instead.",
    [rc.address],
  )
}
