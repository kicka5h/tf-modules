# Full-stack networking example.
#
# The caller defines an IPAM allocation plan in their .tfvars file.
# Everything else — VNets, subnets, NSGs, route tables — derives
# addresses from the IPAM module automatically. No manual CIDR math.

# -----------------------------------------------------------------
# IPAM — calculates all IP addresses from the allocation plan
# -----------------------------------------------------------------

module "ipam" {
  source = "git::https://github.com/<org>/tf-modules.git//Azure/az-ipam?ref=main"

  root_cidrs     = var.ipam_root_cidrs
  reserved_cidrs = var.ipam_reserved_cidrs

  allocations = {
    (var.environment) = var.ipam_allocation
  }
}

# Fail fast if IPAM detects overlaps with existing infrastructure
resource "terraform_data" "ipam_overlap_check" {
  count = module.ipam.has_overlaps ? tobool("IPAM overlap detected — check module.ipam.overlapping_cidrs") : 0
}

# -----------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------
# VNets + Subnets — addresses from IPAM
# -----------------------------------------------------------------

module "vnets" {
  source = "git::https://github.com/<org>/tf-modules.git//Azure/az-virtual-network?ref=main"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  vnets = {
    for vnet_key, vnet in var.ipam_allocation.vnets : vnet_key => {
      name          = "vnet-${var.environment}-${vnet_key}"
      address_space = module.ipam.vnet_cidrs["${var.environment}-${vnet_key}"].address_space
      subnets = {
        for subnet_key, subnet in vnet.subnets : subnet_key => {
          address_prefixes = module.ipam.subnet_cidrs["${var.environment}-${vnet_key}-${subnet_key}"].address_prefixes
        }
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------
# NSGs — one per subnet that has rules defined, addresses from IPAM
# -----------------------------------------------------------------

module "nsgs" {
  source = "git::https://github.com/<org>/tf-modules.git//Azure/az-nsg?ref=main"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  nsgs = {
    for subnet_key, rules in var.nsg_rules : subnet_key => {
      name  = "nsg-${var.environment}-${subnet_key}"
      rules = rules
      # Auto-associate with the matching subnet from the VNet module
      subnet_ids = [
        for vnet_key, vnet in var.ipam_allocation.vnets :
        module.vnets.subnets["${vnet_key}-${subnet_key}"].id
        if contains(keys(vnet.subnets), subnet_key)
      ]
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------
# Route Tables — addresses from IPAM, auto-associated with subnets
# -----------------------------------------------------------------

module "route_tables" {
  source = "git::https://github.com/<org>/tf-modules.git//Azure/az-route-table?ref=main"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  route_tables = {
    for rt_key, rt in var.route_tables : rt_key => {
      name                          = "rt-${var.environment}-${rt_key}"
      bgp_route_propagation_enabled = rt.bgp_route_propagation_enabled
      routes                        = rt.routes
      # Auto-associate with subnets by key
      subnet_ids = [
        for subnet_key in rt.subnet_keys :
        [
          for vnet_key, vnet in var.ipam_allocation.vnets :
          module.vnets.subnets["${vnet_key}-${subnet_key}"].id
          if contains(keys(vnet.subnets), subnet_key)
        ][0]
      ]
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------
# Outputs — expose IDs for other stacks to reference
# -----------------------------------------------------------------

output "ipam_summary" {
  value = module.ipam.summary
}

output "vnet_ids" {
  value = { for k, v in module.vnets.vnets : k => v.id }
}

output "subnet_ids" {
  value = { for k, v in module.vnets.subnets : k => v.id }
}

output "nsg_ids" {
  value = { for k, v in module.nsgs.nsgs : k => v.id }
}

output "route_table_ids" {
  value = { for k, v in module.route_tables.route_tables : k => v.id }
}

output "address_plan" {
  description = "Complete IP address plan for this environment"
  value = {
    environment = module.ipam.environment_cidrs[var.environment]
    vnets       = module.ipam.vnet_cidrs
    subnets     = module.ipam.subnet_cidrs
  }
}
