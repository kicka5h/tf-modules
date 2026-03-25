# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "private_endpoints" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "private_endpoints" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  private_endpoints   = var.private_endpoints
  tags                = var.tags
}

output "private_endpoints" {
  value = module.private_endpoints.private_endpoints
}
