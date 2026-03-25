locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Firewalls that need an inline policy created (no external policy ID provided)
  embedded_policies = {
    for k, fw in var.firewalls : k => fw
    if fw.firewall_policy_id == null
  }

  # Flatten rule collection groups from embedded policies
  rule_collection_groups = {
    for item in flatten([
      for fw_key, fw in local.embedded_policies : [
        for rcg_key, rcg in(fw.policy != null ? fw.policy.rule_collection_groups : {}) : {
          key     = "${fw_key}-${rcg_key}"
          fw_key  = fw_key
          rcg_key = rcg_key
          name    = rcg.name
          priority = rcg.priority
          application_rule_collections = rcg.application_rule_collections
          network_rule_collections     = rcg.network_rule_collections
        }
      ]
    ]) : item.key => item
  }

  # Parse Ultimate Hosts Blacklist into a list of FQDNs
  # Format: "0.0.0.0 bad-domain.com" or "127.0.0.1 bad-domain.com"
  _all_blocklist_fqdns = var.fqdn_blocklist_max > 0 ? [
    for line in split("\n", data.http.hosts_blacklist[0].response_body) :
    trimspace(element(split(" ", trimspace(line)), length(split(" ", trimspace(line))) - 1))
    if length(trimspace(line)) > 0
    && !startswith(trimspace(line), "#")
    && (startswith(trimspace(line), "0.0.0.0") || startswith(trimspace(line), "127.0.0.1"))
    && trimspace(element(split(" ", trimspace(line)), length(split(" ", trimspace(line))) - 1)) != "localhost"
  ] : []

  _ultimate_hosts_fqdns = slice(
    local._all_blocklist_fqdns,
    0,
    min(var.fqdn_blocklist_max, length(local._all_blocklist_fqdns))
  )

  # Parse custom org FQDN blocklist — one domain per line, # for comments
  _custom_fqdns = [
    for line in split("\n", data.http.custom_fqdn_blocklist.response_body) :
    trimspace(line)
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]

  # Combined FQDN blocklist
  blocklist_fqdns = distinct(concat(local._ultimate_hosts_fqdns, local._custom_fqdns))

  # Parse Spamhaus DROP + EDROP into a combined list of CIDRs
  spamhaus_cidrs = distinct(concat(
    [
      for line in split("\n", data.http.spamhaus_drop.response_body) :
      trimspace(split(";", line)[0])
      if trimspace(line) != "" && !startswith(trimspace(line), ";") && !startswith(trimspace(line), "#")
    ],
    [
      for line in split("\n", data.http.spamhaus_edrop.response_body) :
      trimspace(split(";", line)[0])
      if trimspace(line) != "" && !startswith(trimspace(line), ";") && !startswith(trimspace(line), "#")
    ]
  ))

  # Parse custom org IP blocklist — one CIDR per line, # for comments
  custom_ip_cidrs = [
    for line in split("\n", data.http.custom_ip_blocklist.response_body) :
    trimspace(line)
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]

  # Combined IP blocklist
  blocked_cidrs = distinct(concat(local.spamhaus_cidrs, local.custom_ip_cidrs))

  # Apply blocklists to every firewall that has an inline policy (embedded_policies)
  blocklist_firewall_map = length(local.blocklist_fqdns) > 0 || length(local.blocked_cidrs) > 0 ? local.embedded_policies : {}
}

resource "azurerm_firewall_policy" "this" {
  for_each = local.embedded_policies

  name                     = each.value.policy != null ? coalesce(each.value.policy.name, "${each.value.name}-policy") : "${each.value.name}-policy"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = each.value.policy != null ? coalesce(each.value.policy.sku, each.value.sku_tier) : each.value.sku_tier
  threat_intelligence_mode = each.value.policy != null ? each.value.policy.threat_intelligence_mode : "Alert"
  tags                     = local.tags
}

resource "azurerm_firewall" "this" {
  for_each = var.firewalls

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = each.value.sku_name
  sku_tier            = each.value.sku_tier
  threat_intel_mode   = each.value.sku_tier != "Basic" ? each.value.threat_intel_mode : ""
  zones               = each.value.zones
  firewall_policy_id  = each.value.firewall_policy_id != null ? each.value.firewall_policy_id : azurerm_firewall_policy.this[each.key].id
  tags                = local.tags

  ip_configuration {
    name                 = each.value.ip_configuration.name
    subnet_id            = each.value.ip_configuration.subnet_id
    public_ip_address_id = each.value.ip_configuration.public_ip_address_id
  }

  dynamic "management_ip_configuration" {
    for_each = each.value.management_ip_configuration != null ? [each.value.management_ip_configuration] : []
    content {
      name                 = management_ip_configuration.value.name
      subnet_id            = management_ip_configuration.value.subnet_id
      public_ip_address_id = management_ip_configuration.value.public_ip_address_id
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  for_each = local.rule_collection_groups

  name               = each.value.name
  firewall_policy_id = azurerm_firewall_policy.this[each.value.fw_key].id
  priority           = each.value.priority

  dynamic "application_rule_collection" {
    for_each = each.value.application_rule_collections
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = rule.value.name
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = each.value.network_rule_collections
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_fqdns     = rule.value.destination_fqdns
          destination_ports     = rule.value.destination_ports
          protocols             = rule.value.protocols
        }
      }
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "blocklist" {
  for_each = local.blocklist_firewall_map

  name               = "enforced-blocklists"
  firewall_policy_id = azurerm_firewall_policy.this[each.key].id
  priority           = 200

  application_rule_collection {
    name     = "fqdn-blocklist-app-deny"
    priority = 100
    action   = "Deny"

    rule {
      name              = "deny-blocklisted-fqdns-http"
      source_addresses  = ["*"]
      destination_fqdns = local.blocklist_fqdns

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  network_rule_collection {
    name     = "fqdn-blocklist-net-deny"
    priority = 200
    action   = "Deny"

    rule {
      name                  = "deny-blocklisted-fqdns-all-ports"
      source_addresses      = ["*"]
      destination_fqdns     = local.blocklist_fqdns
      destination_ports     = ["*"]
      protocols             = ["TCP", "UDP"]
    }
  }

  network_rule_collection {
    name     = "ip-blocklist-net-deny"
    priority = 300
    action   = "Deny"

    rule {
      name                  = "deny-spamhaus-and-custom-ips-outbound"
      source_addresses      = ["*"]
      destination_addresses = local.blocked_cidrs
      destination_ports     = ["*"]
      protocols             = ["TCP", "UDP", "ICMP"]
    }

    rule {
      name                  = "deny-spamhaus-and-custom-ips-inbound"
      source_addresses      = local.blocked_cidrs
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      protocols             = ["TCP", "UDP", "ICMP"]
    }
  }
}
