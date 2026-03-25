run "storage_account_no_hyphens" {
  command = plan

  variables {
    environment = "dev"
    region      = "eastus"
    workload    = "app"
  }

  assert {
    condition     = output.storage_account == "stappdeveus"
    error_message = "Expected storage_account 'stappdeveus', got '${output.storage_account}'"
  }

  assert {
    condition     = !can(regex("-", output.storage_account))
    error_message = "Storage account name must not contain hyphens"
  }
}

run "storage_account_max_24_chars" {
  command = plan

  variables {
    environment = "stage"
    region      = "southcentralus"
    workload    = "longworkload"
    suffix      = "001"
  }

  assert {
    condition     = length(output.storage_account) <= 24
    error_message = "Storage account name must be 24 chars or fewer, got ${length(output.storage_account)}: '${output.storage_account}'"
  }

  assert {
    condition     = !can(regex("-", output.storage_account))
    error_message = "Storage account name must not contain hyphens"
  }
}

run "container_registry_no_hyphens" {
  command = plan

  variables {
    environment = "prod"
    region      = "westus2"
    workload    = "shared"
  }

  assert {
    condition     = output.container_registry == "crsharedprodwus2"
    error_message = "Expected container_registry 'crsharedprodwus2', got '${output.container_registry}'"
  }

  assert {
    condition     = !can(regex("-", output.container_registry))
    error_message = "Container registry name must not contain hyphens"
  }
}

run "container_registry_max_50_chars" {
  command = plan

  variables {
    environment = "stage"
    region      = "southcentralus"
    workload    = "verylongworkloadnamethatexceedslimits"
    suffix      = "001"
  }

  assert {
    condition     = length(output.container_registry) <= 50
    error_message = "Container registry name must be 50 chars or fewer, got ${length(output.container_registry)}: '${output.container_registry}'"
  }
}

run "key_vault_max_24_chars" {
  command = plan

  variables {
    environment = "stage"
    region      = "southcentralus"
    workload    = "longworkload"
    suffix      = "001"
  }

  assert {
    condition     = length(output.key_vault) <= 24
    error_message = "Key vault name must be 24 chars or fewer, got ${length(output.key_vault)}: '${output.key_vault}'"
  }
}
