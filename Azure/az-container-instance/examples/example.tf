# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_groups" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "container_instance" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  container_groups    = var.container_groups
  tags                = var.tags
}

output "container_groups" {
  value = module.container_instance.container_groups
}

