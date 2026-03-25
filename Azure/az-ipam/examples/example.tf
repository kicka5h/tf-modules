# Usage:
#   1. Run the discovery script to find existing allocations:
#      ./scripts/discover-ip-allocations.sh --tfvars > reserved.auto.tfvars
#
#   2. Plan with your allocation:
#      terraform plan -var-file="example.tfvars"

variable "root_cidrs" {
  type = list(string)
}

variable "reserved_cidrs" {
  type    = list(string)
  default = []
}

variable "allocations" {
  type = any
}

module "ipam" {
  source         = "../"
  root_cidrs     = var.root_cidrs
  reserved_cidrs = var.reserved_cidrs
  allocations    = var.allocations
}

# Outputs for inspection
output "environment_cidrs" {
  value = module.ipam.environment_cidrs
}

output "vnet_cidrs" {
  value = module.ipam.vnet_cidrs
}

output "subnet_cidrs" {
  value = module.ipam.subnet_cidrs
}

output "has_overlaps" {
  value = module.ipam.has_overlaps
}

output "overlapping_cidrs" {
  value = module.ipam.overlapping_cidrs
}

output "summary" {
  value = module.ipam.summary
}

# Example: feed directly into az-virtual-network
# module "vnets" {
#   source              = "../../az-virtual-network"
#   resource_group_name = "rg-networking"
#   location            = "eastus2"
#
#   vnets = {
#     for key, vnet in module.ipam.vnets_for_module : key => {
#       name          = "vnet-${key}"
#       address_space = vnet.address_space
#       subnets = {
#         for sk, sv in vnet.subnets : sk => {
#           address_prefixes = sv.address_prefixes
#         }
#       }
#     }
#   }
# }
