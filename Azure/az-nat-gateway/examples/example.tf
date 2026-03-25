# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "nat_gateways" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "nat_gateways" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  nat_gateways        = var.nat_gateways
  tags                = var.tags
}

output "nat_gateways" {
  value = module.nat_gateways.nat_gateways
}

output "pip_associations" {
  value = module.nat_gateways.pip_associations
}

output "prefix_associations" {
  value = module.nat_gateways.prefix_associations
}

output "subnet_associations" {
  value = module.nat_gateways.subnet_associations
}
