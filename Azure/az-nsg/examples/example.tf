# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "nsgs" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "nsgs" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  nsgs                = var.nsgs
  tags                = var.tags
}

output "nsgs" {
  value = module.nsgs.nsgs
}

output "rules" {
  value = module.nsgs.rules
}

output "subnet_associations" {
  value = module.nsgs.subnet_associations
}

# Spamhaus DROP+EDROP deny rules are automatically enforced on every NSG
output "spamhaus_rules" {
  value = module.nsgs.spamhaus_rules
}
