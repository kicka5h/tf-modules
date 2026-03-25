run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "sandbox"
    owner       = "platform-team"
    cost_center = "CC-1234"
    project     = "test-project"
  }

  expect_failures = [
    var.environment,
  ]
}

run "reject_empty_owner" {
  command = plan

  variables {
    environment = "dev"
    owner       = ""
    cost_center = "CC-1234"
    project     = "test-project"
  }

  expect_failures = [
    var.owner,
  ]
}

run "reject_empty_cost_center" {
  command = plan

  variables {
    environment = "dev"
    owner       = "platform-team"
    cost_center = ""
    project     = "test-project"
  }

  expect_failures = [
    var.cost_center,
  ]
}

run "reject_empty_project" {
  command = plan

  variables {
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
    project     = ""
  }

  expect_failures = [
    var.project,
  ]
}

run "reject_invalid_data_classification" {
  command = plan

  variables {
    environment         = "dev"
    owner               = "platform-team"
    cost_center         = "CC-1234"
    project             = "test-project"
    data_classification = "top-secret"
  }

  expect_failures = [
    var.data_classification,
  ]
}

run "accept_all_valid_environments" {
  command = plan

  variables {
    environment = "prod"
    owner       = "platform-team"
    cost_center = "CC-1234"
    project     = "test-project"
  }

  assert {
    condition     = output.tags["environment"] == "prod"
    error_message = "prod should be a valid environment"
  }
}

run "accept_all_valid_data_classifications" {
  command = plan

  variables {
    environment         = "dev"
    owner               = "platform-team"
    cost_center         = "CC-1234"
    project             = "test-project"
    data_classification = "restricted"
  }

  assert {
    condition     = output.tags["data_classification"] == "restricted"
    error_message = "restricted should be a valid data classification"
  }
}
