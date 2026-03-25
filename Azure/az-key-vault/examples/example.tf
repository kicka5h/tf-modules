# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "key_vaults" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "key_vaults" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vaults          = var.key_vaults
  tags                = var.tags
}

output "key_vaults" {
  value = module.key_vaults.key_vaults
}

output "access_policies" {
  value = module.key_vaults.access_policies
}
