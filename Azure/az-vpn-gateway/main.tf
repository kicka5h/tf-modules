locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten local network gateways into a map for for_each
  local_gateways = {
    for item in flatten([
      for gw_key, gw in var.vpn_gateways : [
        for lgw_key, lgw in gw.local_network_gateways : {
          key             = "${gw_key}-${lgw_key}"
          gw_key          = gw_key
          name            = lgw.name
          gateway_address = lgw.gateway_address
          gateway_fqdn    = lgw.gateway_fqdn
          address_space   = lgw.address_space
          bgp_settings    = lgw.bgp_settings
        }
      ]
    ]) : item.key => item
  }

  # Flatten connections into a map for for_each
  connections = {
    for item in flatten([
      for gw_key, gw in var.vpn_gateways : [
        for conn_key, conn in gw.connections : {
          key                             = "${gw_key}-${conn_key}"
          gw_key                          = gw_key
          name                            = conn.name
          type                            = conn.type
          local_network_gateway_key       = conn.local_network_gateway_key != null ? "${gw_key}-${conn.local_network_gateway_key}" : null
          peer_virtual_network_gateway_id = conn.peer_virtual_network_gateway_id
          express_route_circuit_id        = conn.express_route_circuit_id
          shared_key                      = conn.shared_key
          enable_bgp                      = conn.enable_bgp
          routing_weight                  = conn.routing_weight
          connection_protocol             = conn.connection_protocol
          ipsec_policy                    = conn.ipsec_policy
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_virtual_network_gateway" "this" {
  for_each = var.vpn_gateways

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = each.value.type
  vpn_type            = each.value.vpn_type
  sku                 = each.value.sku
  active_active       = each.value.active_active
  enable_bgp          = each.value.enable_bgp
  generation          = each.value.generation
  tags                = local.tags

  ip_configuration {
    name                          = each.value.ip_configuration.name
    subnet_id                     = each.value.ip_configuration.subnet_id
    public_ip_address_id          = each.value.ip_configuration.public_ip_address_id
    private_ip_address_allocation = each.value.ip_configuration.private_ip_address_allocation
  }

  dynamic "ip_configuration" {
    for_each = each.value.second_ip_configuration != null ? [each.value.second_ip_configuration] : []
    content {
      name                          = ip_configuration.value.name
      subnet_id                     = each.value.ip_configuration.subnet_id
      public_ip_address_id          = ip_configuration.value.public_ip_address_id
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
    }
  }

  dynamic "bgp_settings" {
    for_each = each.value.bgp_settings != null ? [each.value.bgp_settings] : []
    content {
      asn = bgp_settings.value.asn
    }
  }
}

resource "azurerm_local_network_gateway" "this" {
  for_each = local.local_gateways

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = each.value.gateway_address
  gateway_fqdn        = each.value.gateway_fqdn
  address_space       = each.value.address_space
  tags                = local.tags

  dynamic "bgp_settings" {
    for_each = each.value.bgp_settings != null ? [each.value.bgp_settings] : []
    content {
      asn                 = bgp_settings.value.asn
      bgp_peering_address = bgp_settings.value.bgp_peering_address
    }
  }
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each = local.connections

  name                            = each.value.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  type                            = each.value.type
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.this[each.value.gw_key].id
  local_network_gateway_id        = each.value.local_network_gateway_key != null ? azurerm_local_network_gateway.this[each.value.local_network_gateway_key].id : null
  peer_virtual_network_gateway_id = each.value.peer_virtual_network_gateway_id
  express_route_circuit_id        = each.value.express_route_circuit_id
  shared_key                      = each.value.shared_key
  enable_bgp                      = each.value.enable_bgp
  routing_weight                  = each.value.routing_weight
  connection_protocol             = each.value.connection_protocol
  tags                            = local.tags

  dynamic "ipsec_policy" {
    for_each = each.value.ipsec_policy != null ? [each.value.ipsec_policy] : []
    content {
      dh_group         = ipsec_policy.value.dh_group
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
      sa_lifetime      = ipsec_policy.value.sa_lifetime
      sa_datasize      = ipsec_policy.value.sa_datasize
    }
  }
}

# -----------------------------------------------------------------
# Optional: Internal utility module integrations
# Uncomment to enforce naming, tagging, diagnostics, and budget
# at the module level. Callers pass config via the variables above.
# -----------------------------------------------------------------

# --- Naming (generates standardized names for all resources) ---
# module "naming" {
#   source      = "../az-naming"
#   count       = var.naming_config != null ? 1 : 0
#   environment = var.naming_config.environment
#   region      = var.naming_config.region
#   workload    = var.naming_config.workload
# }
# Then replace hardcoded names with: module.naming[0].<resource_type>

# --- Tagging (enforces required tags on all resources) ---
# module "tagging" {
#   source              = "../az-tagging"
#   count               = var.tagging_config != null ? 1 : 0
#   environment         = var.tagging_config.environment
#   owner               = var.tagging_config.owner
#   cost_center         = var.tagging_config.cost_center
#   project             = var.tagging_config.project
#   data_classification = var.tagging_config.data_classification
#   additional_tags     = var.tags
# }
# Then replace local.tags with: var.tagging_config != null ? module.tagging[0].tags : local.tags

# --- Diagnostics (auto-creates diagnostic settings for all resources) ---
# module "diagnostics" {
#   source                     = "../az-diagnostics"
#   count                      = var.diagnostics_config != null ? 1 : 0
#   log_analytics_workspace_id = var.diagnostics_config.log_analytics_workspace_id
#   diagnostic_settings = {
#     for k, v in azurerm_virtual_network_gateway.this : k => {
#       name               = "diag-${v.name}"
#       target_resource_id = v.id
#       storage_account_id = var.diagnostics_config.storage_account_id
#     }
#   }
# }

# --- Budget (creates cost alert for the resource group) ---
# module "budget" {
#   source = "../az-budget"
#   count  = var.budget_config != null ? 1 : 0
#   budgets = {
#     this = {
#       name              = "budget-${var.resource_group_name}"
#       resource_group_id = var.budget_config.resource_group_id
#       amount            = var.budget_config.amount
#       time_period       = { start_date = var.budget_config.start_date }
#       notifications = {
#         actual_80 = {
#           threshold      = 80
#           contact_emails = var.budget_config.contact_emails
#         }
#         actual_100 = {
#           threshold      = 100
#           contact_emails = var.budget_config.contact_emails
#         }
#       }
#     }
#   }
# }
