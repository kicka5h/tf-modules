run "all_required_tags_present" {
  command = plan

  variables {
    environment = "dev"
    owner       = "platform-team"
    cost_center = "CC-1234"
    project     = "landing-zone"
  }

  assert {
    condition     = output.tags["Terraform"] == "true"
    error_message = "Terraform tag must be present and set to true"
  }

  assert {
    condition     = output.tags["environment"] == "dev"
    error_message = "environment tag must match input"
  }

  assert {
    condition     = output.tags["owner"] == "platform-team"
    error_message = "owner tag must match input"
  }

  assert {
    condition     = output.tags["cost_center"] == "CC-1234"
    error_message = "cost_center tag must match input"
  }

  assert {
    condition     = output.tags["data_classification"] == "internal"
    error_message = "data_classification should default to internal"
  }

  assert {
    condition     = output.tags["project"] == "landing-zone"
    error_message = "project tag must match input"
  }

  assert {
    condition     = output.tags["managed_by"] == "terraform"
    error_message = "managed_by should default to terraform"
  }
}

run "required_tags_output_excludes_additional" {
  command = plan

  variables {
    environment    = "prod"
    owner          = "sre-team"
    cost_center    = "CC-5678"
    project        = "api-gateway"
    additional_tags = {
      team = "backend"
    }
  }

  assert {
    condition     = !contains(keys(output.required_tags), "team")
    error_message = "required_tags output must not contain additional tags"
  }

  assert {
    condition     = length(output.required_tags) == 7
    error_message = "required_tags must contain exactly 7 tags"
  }
}
