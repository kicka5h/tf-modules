variable "resource_group_name" {
  description = "Name of the resource group to create firewalls in"
  type        = string
}

variable "location" {
  description = "Azure region for all firewalls"
  type        = string
}

variable "firewalls" {
  description = "Map of firewalls to create. Key is a logical name, value defines the firewall and its optional inline policy."
  type = map(object({
    name              = string
    sku_name          = optional(string, "AZFW_VNet")
    sku_tier          = optional(string, "Standard")
    threat_intel_mode = optional(string, "Alert")
    zones             = optional(list(string), [])
    ip_configuration = object({
      name                 = string
      subnet_id            = string
      public_ip_address_id = string
    })
    management_ip_configuration = optional(object({
      name                 = string
      subnet_id            = string
      public_ip_address_id = string
    }), null)
    dns = optional(object({
      proxy_enabled = optional(bool, false)
      servers       = optional(list(string), [])
    }), null)
    # If set, use an external policy ID. If null, the module creates a policy.
    firewall_policy_id = optional(string, null)
    # Inline policy definition (only used when firewall_policy_id is null)
    policy = optional(object({
      name                     = optional(string, null)  # defaults to "${firewall_name}-policy"
      sku                      = optional(string, null)  # defaults to match firewall sku_tier
      threat_intelligence_mode = optional(string, "Alert")
      rule_collection_groups = optional(map(object({
        name     = string
        priority = number
        application_rule_collections = optional(map(object({
          name     = string
          priority = number
          action   = string # "Allow" or "Deny"
          rules = map(object({
            name              = string
            source_addresses  = optional(list(string), ["*"])
            destination_fqdns = optional(list(string), [])
            protocols = list(object({
              type = string
              port = number
            }))
          }))
        })), {})
        network_rule_collections = optional(map(object({
          name     = string
          priority = number
          action   = string
          rules = map(object({
            name                  = string
            source_addresses      = optional(list(string), ["*"])
            destination_addresses = optional(list(string), [])
            destination_fqdns     = optional(list(string), [])
            destination_ports     = list(string)
            protocols             = list(string)
          }))
        })), {})
      })), {})
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for fw_key, fw in var.firewalls : [
        for rcg_key, rcg in(fw.policy != null ? fw.policy.rule_collection_groups : {}) :
        rcg.priority >= 300
      ]
    ]))
    error_message = "User-defined rule collection group priorities must be >= 300. Priorities 100-299 are reserved for module-enforced blocklist rules."
  }

  validation {
    condition = alltrue([
      for k, fw in var.firewalls :
      contains(["AZFW_VNet", "AZFW_Hub"], fw.sku_name)
    ])
    error_message = "Each firewall must have sku_name set to one of: AZFW_VNet, AZFW_Hub."
  }

  validation {
    condition = alltrue([
      for k, fw in var.firewalls :
      contains(["Basic", "Standard", "Premium"], fw.sku_tier)
    ])
    error_message = "Each firewall must have sku_tier set to one of: Basic, Standard, Premium."
  }

  validation {
    condition = alltrue([
      for k, fw in var.firewalls :
      contains(["Alert", "Deny", "Off"], fw.threat_intel_mode)
    ])
    error_message = "Each firewall must have threat_intel_mode set to one of: Alert, Deny, Off."
  }
}

variable "fqdn_blocklist_max" {
  description = "Maximum number of FQDNs to import from the Ultimate Hosts Blacklist. Set to 0 to disable."
  type        = number
  default     = 1000
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
