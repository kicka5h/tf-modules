# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vpn_gateways" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "vpn_gateways" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  vpn_gateways        = var.vpn_gateways
  tags                = var.tags
}

output "vpn_gateways" {
  value = module.vpn_gateways.vpn_gateways
}

output "local_network_gateways" {
  value = module.vpn_gateways.local_network_gateways
}

output "connections" {
  value = module.vpn_gateways.connections
}
