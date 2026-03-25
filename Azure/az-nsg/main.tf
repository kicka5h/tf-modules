locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten rules into a map for for_each
  rules = {
    for item in flatten([
      for nsg_key, nsg in var.nsgs : [
        for rule_key, rule in nsg.rules : {
          key                                        = "${nsg_key}-${rule_key}"
          nsg_key                                    = nsg_key
          name                                       = rule_key
          priority                                   = rule.priority
          direction                                  = rule.direction
          access                                     = rule.access
          protocol                                   = rule.protocol
          source_port_range                          = rule.source_port_ranges == null ? rule.source_port_range : null
          source_port_ranges                         = rule.source_port_ranges
          destination_port_range                     = rule.destination_port_ranges == null ? rule.destination_port_range : null
          destination_port_ranges                    = rule.destination_port_ranges
          source_address_prefix                      = rule.source_address_prefixes == null && rule.source_application_security_group_ids == null ? rule.source_address_prefix : null
          source_address_prefixes                    = rule.source_address_prefixes
          destination_address_prefix                 = rule.destination_address_prefixes == null && rule.destination_application_security_group_ids == null ? rule.destination_address_prefix : null
          destination_address_prefixes               = rule.destination_address_prefixes
          source_application_security_group_ids      = rule.source_application_security_group_ids
          destination_application_security_group_ids = rule.destination_application_security_group_ids
          description                                = rule.description
        }
      ]
    ]) : item.key => item
  }

  # Flatten subnet associations into a map for for_each
  subnet_associations = {
    for item in flatten([
      for nsg_key, nsg in var.nsgs : [
        for idx, subnet_id in nsg.subnet_ids : {
          key       = "${nsg_key}-${idx}"
          nsg_key   = nsg_key
          subnet_id = subnet_id
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = var.nsgs

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.rules

  name                                       = each.value.name
  resource_group_name                        = var.resource_group_name
  network_security_group_name                = azurerm_network_security_group.this[each.value.nsg_key].name
  priority                                   = each.value.priority
  direction                                  = each.value.direction
  access                                     = each.value.access
  protocol                                   = each.value.protocol
  source_port_range                          = each.value.source_port_range
  source_port_ranges                         = each.value.source_port_ranges
  destination_port_range                     = each.value.destination_port_range
  destination_port_ranges                    = each.value.destination_port_ranges
  source_address_prefix                      = each.value.source_address_prefix
  source_address_prefixes                    = each.value.source_address_prefixes
  destination_address_prefix                 = each.value.destination_address_prefix
  destination_address_prefixes               = each.value.destination_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
  description                                = each.value.description
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnet_associations

  subnet_id                 = each.value.subnet_id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_key].id
}

# --- Spamhaus DROP Blocklist (enforced on all NSGs) ---

data "http" "spamhaus_drop" {
  url = "https://www.spamhaus.org/drop/drop.txt"
}

data "http" "spamhaus_edrop" {
  url = "https://www.spamhaus.org/drop/edrop.txt"
}

data "http" "custom_ip_blocklist" {
  url = "https://raw.githubusercontent.com/<org>/blocked-hosts/main/ip-blocklist.txt"
}

locals {
  # Parse Spamhaus DROP + EDROP into a combined list of CIDRs
  # Format: "1.2.3.0/24 ; SBLxxxxxx" — extract CIDR before the " ;"
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

  # Combined blocklist for all NSG deny rules
  all_blocked_cidrs = distinct(concat(local.spamhaus_cidrs, local.custom_ip_cidrs))
}

resource "azurerm_network_security_rule" "spamhaus_deny_inbound" {
  for_each = var.nsgs

  name                        = "spamhaus-deny-inbound"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.key].name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = local.all_blocked_cidrs
  destination_address_prefix  = "*"
  description                 = "Spamhaus DROP+EDROP and org custom blocklist - deny inbound from known bad IPs"
}

resource "azurerm_network_security_rule" "spamhaus_deny_outbound" {
  for_each = var.nsgs

  name                         = "spamhaus-deny-outbound"
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this[each.key].name
  priority                     = 100
  direction                    = "Outbound"
  access                       = "Deny"
  protocol                     = "*"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefix        = "*"
  destination_address_prefixes = local.all_blocked_cidrs
  description                  = "Spamhaus DROP+EDROP and org custom blocklist - deny outbound to known bad IPs"
}
