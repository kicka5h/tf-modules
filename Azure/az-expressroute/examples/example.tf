# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "expressroute_circuits" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "expressroute" {
  source                = "../"
  resource_group_name   = var.resource_group_name
  location              = var.location
  expressroute_circuits = var.expressroute_circuits
  tags                  = var.tags
}

output "expressroute_circuits" {
  value     = module.expressroute.expressroute_circuits
  sensitive = true
}

output "peerings" {
  value = module.expressroute.peerings
}
