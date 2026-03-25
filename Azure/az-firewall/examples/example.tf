# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "firewalls" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "firewalls" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  firewalls           = var.firewalls
  tags                = var.tags
}

output "firewalls" {
  value = module.firewalls.firewalls
}

output "firewall_policies" {
  value = module.firewalls.firewall_policies
}

output "rule_collection_groups" {
  value = module.firewalls.rule_collection_groups
}

# Ultimate Hosts Blacklist deny rules are automatically enforced
# on every firewall with an inline policy
output "blocklist_rule_collection_groups" {
  value = module.firewalls.blocklist_rule_collection_groups
}

output "blocklist_fqdn_count" {
  value = module.firewalls.blocklist_fqdn_count
}

output "blocklist_ip_count" {
  value = module.firewalls.blocklist_ip_count
}
