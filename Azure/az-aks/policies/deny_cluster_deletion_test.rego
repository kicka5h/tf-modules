package terraform.aks

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_cluster if {
  plan := mock_plan([mock_change("azurerm_kubernetes_cluster", "module.aks.azurerm_kubernetes_cluster.this[\"prod\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_cluster if {
  plan := mock_plan([mock_change("azurerm_kubernetes_cluster", "module.aks.azurerm_kubernetes_cluster.this[\"prod\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_kubernetes_cluster", "module.aks.azurerm_kubernetes_cluster.this[\"prod\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_cluster if {
  plan := mock_plan([mock_change("azurerm_kubernetes_cluster", "module.aks.azurerm_kubernetes_cluster.this[\"prod\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_cluster if {
  plan := mock_plan([mock_change("azurerm_kubernetes_cluster", "module.aks.azurerm_kubernetes_cluster.this[\"prod\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_kubernetes_cluster", "module.aks.azurerm_kubernetes_cluster.this[\"prod\"]", ["delete"]),
    mock_change("azurerm_kubernetes_cluster", "module.aks.azurerm_kubernetes_cluster.this[\"staging\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
