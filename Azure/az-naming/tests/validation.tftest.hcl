run "invalid_environment_rejected" {
  command = plan

  variables {
    environment = "test"
    region      = "eastus"
    workload    = "app"
  }

  expect_failures = [
    var.environment,
  ]
}

run "invalid_workload_rejected" {
  command = plan

  variables {
    environment = "dev"
    region      = "eastus"
    workload    = "my-app"
  }

  expect_failures = [
    var.workload,
  ]
}

run "valid_inputs_accepted" {
  command = plan

  variables {
    environment = "prod"
    region      = "westus2"
    workload    = "data"
  }

  assert {
    condition     = output.base_name == "data-prod-wus2"
    error_message = "Valid inputs should produce base_name 'data-prod-wus2'"
  }
}
