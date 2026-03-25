# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "front_doors" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "front_doors" {
  source              = "../"
  resource_group_name = var.resource_group_name
  front_doors         = var.front_doors
  tags                = var.tags
}

output "profiles" {
  value = module.front_doors.profiles
}

output "endpoints" {
  value = module.front_doors.endpoints
}

output "origin_groups" {
  value = module.front_doors.origin_groups
}

output "origins" {
  value = module.front_doors.origins
}

output "routes" {
  value = module.front_doors.routes
}

output "waf_policies" {
  value = module.front_doors.waf_policies
}

output "blocklist_ip_count" {
  value = module.front_doors.blocklist_ip_count
}

output "blocklist_fqdn_count" {
  value = module.front_doors.blocklist_fqdn_count
}
