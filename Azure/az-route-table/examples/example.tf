# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "route_tables" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "route_tables" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  route_tables        = var.route_tables
  tags                = var.tags
}

output "route_tables" {
  value = module.route_tables.route_tables
}

output "routes" {
  value = module.route_tables.routes
}

output "subnet_associations" {
  value = module.route_tables.subnet_associations
}

