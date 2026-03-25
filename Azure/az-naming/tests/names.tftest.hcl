run "standard_names" {
  command = plan

  variables {
    environment = "dev"
    region      = "eastus"
    workload    = "app"
  }

  assert {
    condition     = output.base_name == "app-dev-eus"
    error_message = "Expected base_name 'app-dev-eus', got '${output.base_name}'"
  }

  assert {
    condition     = output.resource_group == "rg-app-dev-eus"
    error_message = "Expected resource_group 'rg-app-dev-eus', got '${output.resource_group}'"
  }

  assert {
    condition     = output.virtual_network == "vnet-app-dev-eus"
    error_message = "Expected virtual_network 'vnet-app-dev-eus', got '${output.virtual_network}'"
  }

  assert {
    condition     = output.subnet == "snet-app-dev-eus"
    error_message = "Expected subnet 'snet-app-dev-eus', got '${output.subnet}'"
  }

  assert {
    condition     = output.network_security_group == "nsg-app-dev-eus"
    error_message = "Expected network_security_group 'nsg-app-dev-eus', got '${output.network_security_group}'"
  }

  assert {
    condition     = output.key_vault == "kv-app-dev-eus"
    error_message = "Expected key_vault 'kv-app-dev-eus', got '${output.key_vault}'"
  }

  assert {
    condition     = output.aks_cluster == "aks-app-dev-eus"
    error_message = "Expected aks_cluster 'aks-app-dev-eus', got '${output.aks_cluster}'"
  }

  assert {
    condition     = output.dns_zone == "app-dev-eus"
    error_message = "Expected dns_zone 'app-dev-eus', got '${output.dns_zone}'"
  }
}

run "names_with_suffix" {
  command = plan

  variables {
    environment = "prod"
    region      = "westeurope"
    workload    = "data"
    suffix      = "001"
  }

  assert {
    condition     = output.base_name == "data-prod-weu-001"
    error_message = "Expected base_name 'data-prod-weu-001', got '${output.base_name}'"
  }

  assert {
    condition     = output.resource_group == "rg-data-prod-weu-001"
    error_message = "Expected resource_group 'rg-data-prod-weu-001', got '${output.resource_group}'"
  }

  assert {
    condition     = output.virtual_machine == "vm-data-prod-weu-001"
    error_message = "Expected virtual_machine 'vm-data-prod-weu-001', got '${output.virtual_machine}'"
  }
}

run "unknown_region_uses_full_name" {
  command = plan

  variables {
    environment = "qa"
    region      = "brazilsouth"
    workload    = "web"
  }

  assert {
    condition     = output.base_name == "web-qa-brazilsouth"
    error_message = "Expected base_name 'web-qa-brazilsouth', got '${output.base_name}'"
  }
}

run "names_map_contains_all_types" {
  command = plan

  variables {
    environment = "dev"
    region      = "eastus"
    workload    = "app"
  }

  assert {
    condition     = output.names["resource_group"] == output.resource_group
    error_message = "names map resource_group does not match individual output"
  }

  assert {
    condition     = output.names["storage_account"] == output.storage_account
    error_message = "names map storage_account does not match individual output"
  }

  assert {
    condition     = output.names["virtual_network"] == output.virtual_network
    error_message = "names map virtual_network does not match individual output"
  }
}
