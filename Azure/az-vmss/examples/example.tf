# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "scale_sets" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "vmss" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  scale_sets          = var.scale_sets
  tags                = var.tags
}

output "scale_sets" {
  value = module.vmss.scale_sets
}

