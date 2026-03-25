# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "service_plans" {
  type = any
}

variable "web_apps" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "app_service" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plans       = var.service_plans
  web_apps            = var.web_apps
  tags                = var.tags
}

output "service_plans" {
  value = module.app_service.service_plans
}

output "web_apps" {
  value = module.app_service.web_apps
}
