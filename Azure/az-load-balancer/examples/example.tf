# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "load_balancers" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "load_balancers" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  load_balancers      = var.load_balancers
  tags                = var.tags
}

output "load_balancers" {
  value = module.load_balancers.load_balancers
}

output "backend_pools" {
  value = module.load_balancers.backend_pools
}

output "probes" {
  value = module.load_balancers.probes
}

output "rules" {
  value = module.load_balancers.rules
}

output "nat_rules" {
  value = module.load_balancers.nat_rules
}

output "outbound_rules" {
  value = module.load_balancers.outbound_rules
}
