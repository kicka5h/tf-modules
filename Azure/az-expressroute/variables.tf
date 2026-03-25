variable "resource_group_name" {
  description = "Name of the resource group to create ExpressRoute circuits in"
  type        = string
}

variable "location" {
  description = "Azure region for all ExpressRoute circuits"
  type        = string
}

variable "expressroute_circuits" {
  description = "Map of ExpressRoute circuits to create. Key is a logical name, value defines the circuit and its peerings."
  type = map(object({
    name                  = string
    service_provider_name = string
    peering_location      = string
    bandwidth_in_mbps     = number
    sku = object({
      tier   = string # "Standard" or "Premium"
      family = string # "MeteredData" or "UnlimitedData"
    })
    allow_classic_operations = optional(bool, false)
    peerings = optional(map(object({
      peering_type                  = string # "AzurePrivatePeering", "AzurePublicPeering", "MicrosoftPeering"
      vlan_id                       = number
      primary_peer_address_prefix   = string
      secondary_peer_address_prefix = string
      peer_asn                      = optional(number, null)
      shared_key                    = optional(string, null) # sensitive
      microsoft_peering_config = optional(object({
        advertised_public_prefixes = list(string)
      }), null)
    })), {})
  }))
  default = {}

  # Validate sku.tier
  validation {
    condition = alltrue([
      for k, c in var.expressroute_circuits :
      contains(["Standard", "Premium"], c.sku.tier)
    ])
    error_message = "Each circuit must have sku.tier set to one of: Standard, Premium."
  }

  # Validate sku.family
  validation {
    condition = alltrue([
      for k, c in var.expressroute_circuits :
      contains(["MeteredData", "UnlimitedData"], c.sku.family)
    ])
    error_message = "Each circuit must have sku.family set to one of: MeteredData, UnlimitedData."
  }

  # Validate peering_type
  validation {
    condition = alltrue(flatten([
      for c_key, c in var.expressroute_circuits : [
        for p_key, p in c.peerings :
        contains(["AzurePrivatePeering", "AzurePublicPeering", "MicrosoftPeering"], p.peering_type)
      ]
    ]))
    error_message = "Each peering must have peering_type set to one of: AzurePrivatePeering, AzurePublicPeering, MicrosoftPeering."
  }

  # Validate MicrosoftPeering requires microsoft_peering_config
  validation {
    condition = alltrue(flatten([
      for c_key, c in var.expressroute_circuits : [
        for p_key, p in c.peerings :
        p.peering_type != "MicrosoftPeering" || p.microsoft_peering_config != null
      ]
    ]))
    error_message = "MicrosoftPeering requires microsoft_peering_config to be set."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
