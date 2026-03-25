# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_accounts" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "storage_accounts" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  storage_accounts    = var.storage_accounts
  tags                = var.tags
}

output "storage_accounts" {
  value     = module.storage_accounts.storage_accounts
  sensitive = true
}

output "containers" {
  value = module.storage_accounts.containers
}

output "file_shares" {
  value = module.storage_accounts.file_shares
}

output "queues" {
  value = module.storage_accounts.queues
}

output "tables" {
  value = module.storage_accounts.tables
}
