variable "resource_group_name" {
  description = "Name of the resource group to create container registries in"
  type        = string
}

variable "location" {
  description = "Azure region for all container registries"
  type        = string
}

variable "container_registries" {
  description = "Map of container registries to create. Key is a logical name, value defines the registry configuration."
  type = map(object({
    name = string
    # Enforce: Premium SKU for private endpoints and zone redundancy
    sku = optional(string, "Premium")
    # Enforce: admin user disabled
    admin_enabled = optional(bool, false)
    # Enforce: zone redundancy for Premium
    zone_redundancy_enabled = optional(bool, true)
    # Enforce: public network access disabled by default
    public_network_access_enabled = optional(bool, false)
    network_rule_bypass_option    = optional(string, "AzureServices")
    # Enforce: content trust (image signing)
    trust_policy_enabled = optional(bool, true)
    # Retention policy for untagged manifests
    retention_policy = optional(object({
      days    = optional(number, 30)
      enabled = optional(bool, true)
    }), { days = 30, enabled = true })
    # Georeplications for Premium SKU
    georeplications = optional(map(object({
      location                = string
      zone_redundancy_enabled = optional(bool, true)
      tags                    = optional(map(string), {})
    })), {})
    # Encryption with customer-managed key
    encryption = optional(object({
      key_vault_key_id   = string
      identity_client_id = string
    }), null)
    # Identity
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, r in var.container_registries :
      contains(["Basic", "Standard", "Premium"], r.sku)
    ])
    error_message = "Each registry must have sku set to one of: Basic, Standard, Premium."
  }

  validation {
    condition = alltrue([
      for k, r in var.container_registries :
      r.admin_enabled == false
    ])
    error_message = "Admin user must be disabled on all container registries (admin_enabled = false)."
  }

  validation {
    condition = alltrue([
      for k, r in var.container_registries :
      r.public_network_access_enabled == false
    ])
    error_message = "Public network access must be disabled on all container registries (public_network_access_enabled = false)."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
