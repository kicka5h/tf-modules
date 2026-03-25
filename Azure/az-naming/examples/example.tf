# Generate standardized names for a dev environment in East US
module "naming" {
  source = "../"

  environment = var.environment
  region      = var.region
  workload    = var.workload
  suffix      = var.suffix
}

# Use the naming module with az-virtual-network
module "vnet" {
  source = "../../az-virtual-network"

  resource_group_name = module.naming.resource_group
  location            = var.region

  vnets = {
    hub = {
      name          = module.naming.virtual_network
      address_space = ["10.0.0.0/16"]
      subnets = {
        default = {
          name             = "${module.naming.subnet}-default"
          address_prefixes = ["10.0.1.0/24"]
        }
        appgw = {
          name             = "${module.naming.subnet}-appgw"
          address_prefixes = ["10.0.2.0/24"]
        }
      }
    }
  }
}

# Reference individual names
output "all_names" {
  description = "All generated resource names"
  value       = module.naming.names
}

output "resource_group_name" {
  description = "Generated resource group name"
  value       = module.naming.resource_group
}

output "storage_account_name" {
  description = "Generated storage account name (no hyphens, max 24 chars)"
  value       = module.naming.storage_account
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "eastus"
}

variable "workload" {
  type    = string
  default = "app"
}

variable "suffix" {
  type    = string
  default = ""
}
