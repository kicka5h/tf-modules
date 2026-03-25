package terraform.appservice

import rego.v1

# -- Helpers to build test plans --

mock_plan(resource_changes) := {"resource_changes": resource_changes}

mock_change(type, address, actions) := {
  "type": type,
  "address": address,
  "change": {"actions": actions},
}

# -- No deletions: should pass --

test_allow_create_service_plan if {
  plan := mock_plan([mock_change("azurerm_service_plan", "module.app.azurerm_service_plan.this[\"main\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_create_linux_web_app if {
  plan := mock_plan([mock_change("azurerm_linux_web_app", "module.app.azurerm_linux_web_app.this[\"api\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_create_windows_web_app if {
  plan := mock_plan([mock_change("azurerm_windows_web_app", "module.app.azurerm_windows_web_app.this[\"web\"]", ["create"])])
  count(deny) == 0 with input as plan
}

test_allow_update_service_plan if {
  plan := mock_plan([mock_change("azurerm_service_plan", "module.app.azurerm_service_plan.this[\"main\"]", ["update"])])
  count(deny) == 0 with input as plan
}

test_allow_no_op if {
  plan := mock_plan([mock_change("azurerm_linux_web_app", "module.app.azurerm_linux_web_app.this[\"api\"]", ["no-op"])])
  count(deny) == 0 with input as plan
}

# -- Deletions: should deny --

test_deny_delete_service_plan if {
  plan := mock_plan([mock_change("azurerm_service_plan", "module.app.azurerm_service_plan.this[\"main\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_delete_linux_web_app if {
  plan := mock_plan([mock_change("azurerm_linux_web_app", "module.app.azurerm_linux_web_app.this[\"api\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_delete_windows_web_app if {
  plan := mock_plan([mock_change("azurerm_windows_web_app", "module.app.azurerm_windows_web_app.this[\"web\"]", ["delete"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_service_plan if {
  plan := mock_plan([mock_change("azurerm_service_plan", "module.app.azurerm_service_plan.this[\"main\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_linux_web_app if {
  plan := mock_plan([mock_change("azurerm_linux_web_app", "module.app.azurerm_linux_web_app.this[\"api\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

test_deny_replace_windows_web_app if {
  plan := mock_plan([mock_change("azurerm_windows_web_app", "module.app.azurerm_windows_web_app.this[\"web\"]", ["delete", "create"])])
  count(deny) == 1 with input as plan
}

# -- Multiple deletions --

test_deny_multiple_deletions if {
  plan := mock_plan([
    mock_change("azurerm_service_plan", "module.app.azurerm_service_plan.this[\"a\"]", ["delete"]),
    mock_change("azurerm_linux_web_app", "module.app.azurerm_linux_web_app.this[\"b\"]", ["delete"]),
    mock_change("azurerm_windows_web_app", "module.app.azurerm_windows_web_app.this[\"c\"]", ["delete"]),
  ])
  count(deny) == 3 with input as plan
}

# -- Unrelated resources: should not trigger --

test_allow_delete_unrelated_resource if {
  plan := mock_plan([mock_change("azurerm_resource_group", "azurerm_resource_group.main", ["delete"])])
  count(deny) == 0 with input as plan
}
