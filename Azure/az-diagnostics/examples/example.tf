# Usage: terraform plan -var-file="example.tfvars"

variable "log_analytics_workspace_id" {
  type = string
}

variable "diagnostic_settings" {
  type = any
}

module "diagnostics" {
  source                     = "../"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  diagnostic_settings        = var.diagnostic_settings
}

output "diagnostic_settings" {
  value = module.diagnostics.diagnostic_settings
}
