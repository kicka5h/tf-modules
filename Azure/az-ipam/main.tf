locals {
  # Calculate environment CIDRs from root
  environment_cidrs = {
    for env_key, env in var.allocations :
    env_key => cidrsubnet(var.root_cidrs[0], env.cidr_newbits, env.cidr_index)
  }

  # Calculate VNet CIDRs from environment CIDRs
  vnet_cidrs = {
    for item in flatten([
      for env_key, env in var.allocations : [
        for vnet_key, vnet in env.vnets : {
          key      = "${env_key}-${vnet_key}"
          env_key  = env_key
          vnet_key = vnet_key
          cidr     = cidrsubnet(local.environment_cidrs[env_key], vnet.cidr_newbits, vnet.cidr_index)
        }
      ]
    ]) : item.key => item
  }

  # Calculate subnet CIDRs from VNet CIDRs
  subnet_cidrs = {
    for item in flatten([
      for env_key, env in var.allocations : [
        for vnet_key, vnet in env.vnets : [
          for subnet_key, subnet in vnet.subnets : {
            key        = "${env_key}-${vnet_key}-${subnet_key}"
            env_key    = env_key
            vnet_key   = vnet_key
            subnet_key = subnet_key
            vnet_cidr_key = "${env_key}-${vnet_key}"
            cidr       = cidrsubnet(local.vnet_cidrs["${env_key}-${vnet_key}"].cidr, subnet.cidr_newbits, subnet.cidr_index)
          }
        ]
      ]
    ]) : item.key => item
  }

  # All newly allocated CIDRs (for overlap checking)
  all_new_cidrs = concat(
    [for k, v in local.environment_cidrs : v],
    [for k, v in local.vnet_cidrs : v.cidr],
    [for k, v in local.subnet_cidrs : v.cidr]
  )

  # Build VNet output map (for direct use with az-virtual-network module)
  vnets_for_module = {
    for item in flatten([
      for env_key, env in var.allocations : [
        for vnet_key, vnet in env.vnets : {
          key           = "${env_key}-${vnet_key}"
          address_space = [local.vnet_cidrs["${env_key}-${vnet_key}"].cidr]
          subnets = {
            for subnet_key, subnet in vnet.subnets :
            subnet_key => {
              address_prefixes = [local.subnet_cidrs["${env_key}-${vnet_key}-${subnet_key}"].cidr]
            }
          }
        }
      ]
    ]) : item.key => item
  }

  # Overlap detection: check each reserved CIDR against each new CIDR
  # Uses cidrhost to get the network address and checks containment
  # This is a simplified check — it detects if any new allocation starts within a reserved range
  overlap_checks = [
    for pair in setproduct(var.reserved_cidrs, local.all_new_cidrs) : {
      reserved = pair[0]
      new      = pair[1]
      # Check if the new CIDR's first host falls within the reserved range
      overlaps = (
        cidrhost(pair[1], 0) == cidrhost(pair[0], 0) ? true :
        can(cidrsubnet(pair[0], 0, 0)) && can(cidrsubnet(pair[1], 0, 0)) ?
        cidrcontains(pair[0], cidrhost(pair[1], 0)) || cidrcontains(pair[1], cidrhost(pair[0], 0)) :
        false
      )
    }
  ]

  overlapping_cidrs = [
    for check in local.overlap_checks : check
    if check.overlaps
  ]
}
