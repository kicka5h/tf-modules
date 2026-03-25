output "environment_cidrs" {
  description = "Map of environment name to allocated CIDR block"
  value       = local.environment_cidrs
}

output "vnet_cidrs" {
  description = "Map of vnet key (env-vnet) to allocated CIDR block and address_space list"
  value = {
    for k, v in local.vnet_cidrs : k => {
      cidr          = v.cidr
      address_space = [v.cidr]
      env_key       = v.env_key
      vnet_key      = v.vnet_key
    }
  }
}

output "subnet_cidrs" {
  description = "Map of subnet key (env-vnet-subnet) to allocated CIDR block and address_prefixes list"
  value = {
    for k, v in local.subnet_cidrs : k => {
      cidr             = v.cidr
      address_prefixes = [v.cidr]
      env_key          = v.env_key
      vnet_key         = v.vnet_key
      subnet_key       = v.subnet_key
    }
  }
}

output "vnets_for_module" {
  description = "Pre-built VNet map that can be passed directly to the az-virtual-network module's vnets variable (add name and other fields in the caller)"
  value       = local.vnets_for_module
}

output "overlapping_cidrs" {
  description = "List of overlaps detected between new allocations and reserved CIDRs. Should be empty."
  value       = local.overlapping_cidrs
}

output "has_overlaps" {
  description = "True if any new allocation overlaps with a reserved CIDR"
  value       = length(local.overlapping_cidrs) > 0
}

output "summary" {
  description = "Summary of all allocations"
  value = {
    root_cidrs          = var.root_cidrs
    reserved_cidr_count = length(var.reserved_cidrs)
    environments        = keys(var.allocations)
    total_vnets         = length(local.vnet_cidrs)
    total_subnets       = length(local.subnet_cidrs)
    overlap_count       = length(local.overlapping_cidrs)
  }
}
