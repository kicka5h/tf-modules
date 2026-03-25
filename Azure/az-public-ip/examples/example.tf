# Usage: terraform plan -var-file="example.tfvars"

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "public_ips" {
  type = any
}

variable "public_ip_prefixes" {
  type    = any
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

module "public_ip" {
  source              = "../"
  resource_group_name = var.resource_group_name
  location            = var.location
  public_ips          = var.public_ips
  public_ip_prefixes  = var.public_ip_prefixes
  tags                = var.tags
}

# Reference outputs — one entry per public IP
output "public_ips" {
  value = module.public_ip.public_ips
}

# Reference outputs — one entry per public IP prefix
output "public_ip_prefixes" {
  value = module.public_ip.public_ip_prefixes
}

