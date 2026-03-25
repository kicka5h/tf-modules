package terraform.expressroute

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_circuit if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit", "module.er.azurerm_express_route_circuit.this[\"primary\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_create_peering if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit_peering", "module.er.azurerm_express_route_circuit_peering.this[\"primary-private\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_circuit if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit", "module.er.azurerm_express_route_circuit.this[\"primary\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_update_peering if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit_peering", "module.er.azurerm_express_route_circuit_peering.this[\"primary-private\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit", "module.er.azurerm_express_route_circuit.this[\"primary\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_circuit if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit", "module.er.azurerm_express_route_circuit.this[\"primary\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_delete_peering if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit_peering", "module.er.azurerm_express_route_circuit_peering.this[\"primary-private\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_circuit if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit", "module.er.azurerm_express_route_circuit.this[\"primary\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_peering if {
  plan := mock_plan([mock_change("azurerm_express_route_circuit_peering", "module.er.azurerm_express_route_circuit_peering.this[\"primary-private\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_express_route_circuit", "module.er.azurerm_express_route_circuit.this[\"a\"]", ["delete"]),
    mock_change("azurerm_express_route_circuit_peering", "module.er.azurerm_express_route_circuit_peering.this[\"a-private\"]", ["delete"]),
  ])
  count(deny) == 2 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
