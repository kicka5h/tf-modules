package terraform.cost.aks_scaling

import rego.v1

# Restrict AKS node pool scaling in non-production environments.
# Prevents dev/qa from running production-sized clusters.

max_nodes_nonprod := 10
max_nodes_prod := 100

is_nonprod if {
  env := input.variables.environment.value
  env in {"dev", "qa"}
}

is_nonprod if {
  tags := input.planned_values.root_module.resources[_].values.tags
  tags.environment in {"dev", "qa"}
}

# Default node pool max_count
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster"
  "create" in rc.change.actions
  pool := rc.change.after.default_node_pool[0]
  pool.max_count != null
  pool.max_count > max_nodes_nonprod
  msg := sprintf(
    "Cost policy: AKS cluster '%s' default node pool max_count=%d exceeds non-production limit of %d.",
    [rc.address, pool.max_count, max_nodes_nonprod],
  )
}

# Additional node pool max_count
deny contains msg if {
  is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster_node_pool"
  "create" in rc.change.actions
  rc.change.after.max_count != null
  rc.change.after.max_count > max_nodes_nonprod
  msg := sprintf(
    "Cost policy: AKS node pool '%s' max_count=%d exceeds non-production limit of %d.",
    [rc.address, rc.change.after.max_count, max_nodes_nonprod],
  )
}

# Production guardrail: still cap at a reasonable max
deny contains msg if {
  not is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster"
  "create" in rc.change.actions
  pool := rc.change.after.default_node_pool[0]
  pool.max_count != null
  pool.max_count > max_nodes_prod
  msg := sprintf(
    "Cost policy: AKS cluster '%s' default node pool max_count=%d exceeds production limit of %d. Request an exception.",
    [rc.address, pool.max_count, max_nodes_prod],
  )
}

deny contains msg if {
  not is_nonprod
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster_node_pool"
  "create" in rc.change.actions
  rc.change.after.max_count != null
  rc.change.after.max_count > max_nodes_prod
  msg := sprintf(
    "Cost policy: AKS node pool '%s' max_count=%d exceeds production limit of %d. Request an exception.",
    [rc.address, rc.change.after.max_count, max_nodes_prod],
  )
}
