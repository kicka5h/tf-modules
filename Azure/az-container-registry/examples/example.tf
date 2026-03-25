# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_registries" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "container_registries" {
  source               = "../"
  resource_group_name  = var.resource_group_name
  location             = var.location
  container_registries = var.container_registries
  tags                 = var.tags
}

output "container_registries" {
  value = module.container_registries.container_registries
}

