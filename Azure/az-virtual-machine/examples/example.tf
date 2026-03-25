# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "virtual_machines" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "virtual_machines" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_machines    = var.virtual_machines
  tags                = var.tags
}

output "virtual_machines" {
  value = module.virtual_machines.virtual_machines
}

output "network_interfaces" {
  value = module.virtual_machines.network_interfaces
}

output "data_disks" {
  value = module.virtual_machines.data_disks
}
