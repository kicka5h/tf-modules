# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnets" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "network" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnets               = var.vnets
  tags                = var.tags
}

# Reference outputs — one entry per vnet
output "vnets" {
  value = module.network.vnets
}

# Reference outputs — one entry per subnet (keyed as "vnet-subnet")
output "subnets" {
  value = module.network.subnets
}

