locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten public IP associations into a map for for_each
  pip_associations = {
    for item in flatten([
      for gw_key, gw in var.nat_gateways : [
        for idx, pip_id in gw.public_ip_ids : {
          key          = "${gw_key}-${idx}"
          gw_key       = gw_key
          public_ip_id = pip_id
        }
      ]
    ]) : item.key => item
  }

  # Flatten public IP prefix associations into a map for for_each
  prefix_associations = {
    for item in flatten([
      for gw_key, gw in var.nat_gateways : [
        for idx, prefix_id in gw.public_ip_prefix_ids : {
          key                 = "${gw_key}-${idx}"
          gw_key              = gw_key
          public_ip_prefix_id = prefix_id
        }
      ]
    ]) : item.key => item
  }

  # Flatten subnet associations into a map for for_each
  subnet_associations = {
    for item in flatten([
      for gw_key, gw in var.nat_gateways : [
        for idx, subnet_id in gw.subnet_ids : {
          key       = "${gw_key}-${idx}"
          gw_key    = gw_key
          subnet_id = subnet_id
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_nat_gateway" "this" {
  for_each = var.nat_gateways

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = each.value.sku_name
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones
  tags                    = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  for_each = local.pip_associations

  nat_gateway_id       = azurerm_nat_gateway.this[each.value.gw_key].id
  public_ip_address_id = each.value.public_ip_id
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "this" {
  for_each = local.prefix_associations

  nat_gateway_id      = azurerm_nat_gateway.this[each.value.gw_key].id
  public_ip_prefix_id = each.value.public_ip_prefix_id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = local.subnet_associations

  subnet_id      = each.value.subnet_id
  nat_gateway_id = azurerm_nat_gateway.this[each.value.gw_key].id
}

# -----------------------------------------------------------------
# Optional: Internal utility module integrations
# Uncomment to enforce naming, tagging, and budget
# at the module level. Callers pass config via the variables above.
# Note: Diagnostics are not supported for NAT gateways.
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
