run "additional_tags_merge_correctly" {
  command = plan

  variables {
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
    project     = "landing-zone"
    additional_tags = {
      team       = "backend"
      department = "engineering"
    }
  }

  assert {
    condition     = output.tags["team"] == "backend"
    error_message = "additional tag 'team' must be present in merged output"
  }

  assert {
    condition     = output.tags["department"] == "engineering"
    error_message = "additional tag 'department' must be present in merged output"
  }

  # Required tags must still be present
  assert {
    condition     = output.tags["environment"] == "dev"
    error_message = "required tags must survive the merge"
  }
}

run "additional_tags_cannot_override_required" {
  command = plan

  variables {
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
    project     = "landing-zone"
    additional_tags = {
      environment = "hacked"
      owner       = "attacker"
      Terraform   = "false"
    }
  }

  assert {
    condition     = output.tags["environment"] == "dev"
    error_message = "additional_tags must not override required environment tag"
  }

  assert {
    condition     = output.tags["owner"] == "platform-team"
    error_message = "additional_tags must not override required owner tag"
  }

  assert {
    condition     = output.tags["Terraform"] == "true"
    error_message = "additional_tags must not override required Terraform tag"
  }
}

run "empty_additional_tags_is_fine" {
  command = plan

  variables {
    environment = "qa"
    owner       = "qa-team"
    cost_center = "CC-9999"
    project     = "smoke-test"
  }

  assert {
    condition     = length(output.tags) == 7
    error_message = "with no additional tags, output should have exactly 7 required tags"
  }
}
