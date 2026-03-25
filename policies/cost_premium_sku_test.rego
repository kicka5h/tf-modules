package terraform.cost.premium_sku

import rego.v1

mock_plan(env, resource_type, fields) := {
  "variables": {"environment": {"value": env}},
  "planned_values": {"root_module": {"resources": []}},
  "resource_changes": [{
    "type": resource_type,
    "address": "module.test.resource[\"test\"]",
    "change": {
      "actions": ["create"],
      "after": fields,
    },
  }],
}

test_deny_premium_firewall_in_dev if {
  plan := mock_plan("dev", "azurerm_firewall", {"sku_tier": "Premium"})
  count(deny) == 1 with input as plan
}

test_allow_standard_firewall_in_dev if {
  plan := mock_plan("dev", "azurerm_firewall", {"sku_tier": "Standard"})
  count(deny) == 0 with input as plan
}

test_allow_premium_firewall_in_prod if {
  plan := mock_plan("prod", "azurerm_firewall", {"sku_tier": "Premium"})
  count(deny) == 0 with input as plan
}

test_deny_premium_appservice_in_qa if {
  plan := mock_plan("qa", "azurerm_service_plan", {"sku_name": "P1v3"})
  count(deny) == 1 with input as plan
}

test_allow_basic_appservice_in_dev if {
  plan := mock_plan("dev", "azurerm_service_plan", {"sku_name": "B1"})
  count(deny) == 0 with input as plan
}

test_deny_premium_aks_in_dev if {
  plan := mock_plan("dev", "azurerm_kubernetes_cluster", {"sku_tier": "Premium"})
  count(deny) == 1 with input as plan
}

test_deny_premium_frontdoor_in_dev if {
  plan := mock_plan("dev", "azurerm_cdn_frontdoor_profile", {"sku_name": "Premium_AzureFrontDoor"})
  count(deny) == 1 with input as plan
}

test_allow_standard_frontdoor_in_dev if {
  plan := mock_plan("dev", "azurerm_cdn_frontdoor_profile", {"sku_name": "Standard_AzureFrontDoor"})
  count(deny) == 0 with input as plan
}
