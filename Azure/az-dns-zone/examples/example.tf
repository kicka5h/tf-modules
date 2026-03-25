# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "dns_zones" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "dns" {
  source              = "../"
  resource_group_name = var.resource_group_name
  dns_zones           = var.dns_zones
  tags                = var.tags
}

# Reference outputs — one entry per public zone
output "public_dns_zones" {
  value = module.dns.public_dns_zones
}

# Reference outputs — one entry per private zone
output "private_dns_zones" {
  value = module.dns.private_dns_zones
}

# Reference outputs — one entry per vnet link
output "private_dns_zone_vnet_links" {
  value = module.dns.private_dns_zone_vnet_links
}
