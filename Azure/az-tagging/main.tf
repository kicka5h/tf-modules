locals {
  required_tags = {
    Terraform           = "true"
    environment         = var.environment
    owner               = var.owner
    cost_center         = var.cost_center
    data_classification = var.data_classification
    project             = var.project
    managed_by          = var.managed_by
  }

  # Merge additional tags on top of required tags.
  # Required tags take precedence — they are merged last to prevent overrides.
  tags = merge(var.additional_tags, local.required_tags)
}
