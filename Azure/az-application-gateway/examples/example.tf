# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "application_gateways" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "application_gateways" {
  source               = "../"
  resource_group_name  = var.resource_group_name
  location             = var.location
  application_gateways = var.application_gateways
  tags                 = var.tags
}

output "application_gateways" {
  value = module.application_gateways.application_gateways
}

# WAF policies with Spamhaus + custom org IP blocklist are automatically
# enforced on every WAF_v2 application gateway
output "waf_policies" {
  value = module.application_gateways.waf_policies
}

output "blocklist_ip_count" {
  value = module.application_gateways.blocklist_ip_count
}

