# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "aks_clusters" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "aks" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  aks_clusters        = var.aks_clusters
  tags                = var.tags
}

output "aks_clusters" {
  value     = module.aks.aks_clusters
  sensitive = true
}

output "additional_node_pools" {
  value = module.aks.additional_node_pools
}
