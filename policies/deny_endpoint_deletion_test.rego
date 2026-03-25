package terraform.private_endpoint

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_endpoint if {
  plan := mock_plan([mock_change("azurerm_private_endpoint", "module.pe.azurerm_private_endpoint.this[\"storage\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_endpoint if {
  plan := mock_plan([mock_change("azurerm_private_endpoint", "module.pe.azurerm_private_endpoint.this[\"storage\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_private_endpoint", "module.pe.azurerm_private_endpoint.this[\"storage\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_endpoint if {
  plan := mock_plan([mock_change("azurerm_private_endpoint", "module.pe.azurerm_private_endpoint.this[\"storage\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_endpoint if {
  plan := mock_plan([mock_change("azurerm_private_endpoint", "module.pe.azurerm_private_endpoint.this[\"storage\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_private_endpoint", "module.pe.azurerm_private_endpoint.this[\"storage\"]", ["delete"]),
    mock_change("azurerm_private_endpoint", "module.pe.azurerm_private_endpoint.this[\"keyvault\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
