locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten backend pools into a map for for_each
  backend_pools = {
    for item in flatten([
      for lb_key, lb in var.load_balancers : [
        for pool_key, pool in lb.backend_pools : {
          key    = "${lb_key}-${pool_key}"
          lb_key = lb_key
          name   = pool.name
        }
      ]
    ]) : item.key => item
  }

  # Flatten probes into a map for for_each
  probes = {
    for item in flatten([
      for lb_key, lb in var.load_balancers : [
        for probe_key, probe in lb.probes : {
          key                 = "${lb_key}-${probe_key}"
          lb_key              = lb_key
          name                = probe.name
          protocol            = probe.protocol
          port                = probe.port
          request_path        = probe.request_path
          interval_in_seconds = probe.interval_in_seconds
          number_of_probes    = probe.number_of_probes
        }
      ]
    ]) : item.key => item
  }

  # Flatten rules into a map for for_each
  rules = {
    for item in flatten([
      for lb_key, lb in var.load_balancers : [
        for rule_key, rule in lb.rules : {
          key                            = "${lb_key}-${rule_key}"
          lb_key                         = lb_key
          name                           = rule.name
          protocol                       = rule.protocol
          frontend_port                  = rule.frontend_port
          backend_port                   = rule.backend_port
          frontend_ip_configuration_name = rule.frontend_ip_configuration_name
          backend_address_pool_key       = "${lb_key}-${rule.backend_address_pool_key}"
          probe_key                      = "${lb_key}-${rule.probe_key}"
          enable_floating_ip             = rule.enable_floating_ip
          idle_timeout_in_minutes        = rule.idle_timeout_in_minutes
          load_distribution              = rule.load_distribution
          disable_outbound_snat          = rule.disable_outbound_snat
        }
      ]
    ]) : item.key => item
  }

  # Flatten NAT rules into a map for for_each
  nat_rules = {
    for item in flatten([
      for lb_key, lb in var.load_balancers : [
        for nat_key, nat in lb.nat_rules : {
          key                            = "${lb_key}-${nat_key}"
          lb_key                         = lb_key
          name                           = nat.name
          protocol                       = nat.protocol
          frontend_port                  = nat.frontend_port
          backend_port                   = nat.backend_port
          frontend_ip_configuration_name = nat.frontend_ip_configuration_name
        }
      ]
    ]) : item.key => item
  }

  # Flatten outbound rules into a map for for_each
  outbound_rules = {
    for item in flatten([
      for lb_key, lb in var.load_balancers : [
        for ob_key, ob in lb.outbound_rules : {
          key                            = "${lb_key}-${ob_key}"
          lb_key                         = lb_key
          name                           = ob.name
          protocol                       = ob.protocol
          frontend_ip_configuration_name = ob.frontend_ip_configuration_name
          backend_address_pool_key       = "${lb_key}-${ob.backend_address_pool_key}"
          allocated_outbound_ports       = ob.allocated_outbound_ports
          idle_timeout_in_minutes        = ob.idle_timeout_in_minutes
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_lb" "this" {
  for_each = var.load_balancers

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = each.value.sku
  sku_tier            = each.value.sku_tier
  tags                = local.tags

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configurations
    content {
      name                          = frontend_ip_configuration.value.name
      public_ip_address_id          = frontend_ip_configuration.value.public_ip_address_id
      subnet_id                     = frontend_ip_configuration.value.subnet_id
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation = frontend_ip_configuration.value.subnet_id != null ? frontend_ip_configuration.value.private_ip_address_allocation : null
      zones                         = frontend_ip_configuration.value.zones
    }
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = local.backend_pools

  name            = each.value.name
  loadbalancer_id = azurerm_lb.this[each.value.lb_key].id
}

resource "azurerm_lb_probe" "this" {
  for_each = local.probes

  name                = each.value.name
  loadbalancer_id     = azurerm_lb.this[each.value.lb_key].id
  protocol            = each.value.protocol
  port                = each.value.port
  request_path        = each.value.protocol != "Tcp" ? each.value.request_path : null
  interval_in_seconds = each.value.interval_in_seconds
  number_of_probes    = each.value.number_of_probes
}

resource "azurerm_lb_rule" "this" {
  for_each = local.rules

  name                           = each.value.name
  loadbalancer_id                = azurerm_lb.this[each.value.lb_key].id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this[each.value.backend_address_pool_key].id]
  probe_id                       = azurerm_lb_probe.this[each.value.probe_key].id
  enable_floating_ip             = each.value.enable_floating_ip
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  load_distribution              = each.value.load_distribution
  disable_outbound_snat          = each.value.disable_outbound_snat
}

resource "azurerm_lb_nat_rule" "this" {
  for_each = local.nat_rules

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.this[each.value.lb_key].id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
}

resource "azurerm_lb_outbound_rule" "this" {
  for_each = local.outbound_rules

  name                    = each.value.name
  loadbalancer_id         = azurerm_lb.this[each.value.lb_key].id
  protocol                = each.value.protocol
  backend_address_pool_id = azurerm_lb_backend_address_pool.this[each.value.backend_address_pool_key].id
  allocated_outbound_ports = each.value.allocated_outbound_ports
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes

  frontend_ip_configuration {
    name = each.value.frontend_ip_configuration_name
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
#     for k, v in azurerm_lb.this : k => {
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
