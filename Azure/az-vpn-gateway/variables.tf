variable "resource_group_name" {
  description = "Name of the resource group to create VPN gateways in"
  type        = string
}

variable "location" {
  description = "Azure region for all VPN gateways"
  type        = string
}

variable "vpn_gateways" {
  description = "Map of VPN gateways to create. Key is a logical name, value defines the gateway, local network gateways, and connections."
  type = map(object({
    name          = string
    type          = optional(string, "Vpn")           # "Vpn" or "ExpressRoute"
    vpn_type      = optional(string, "RouteBased")    # "RouteBased" or "PolicyBased"
    sku           = string                             # "Basic", "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"
    active_active = optional(bool, false)
    enable_bgp    = optional(bool, false)
    generation    = optional(string, "Generation2")    # "Generation1", "Generation2", "None"
    ip_configuration = object({
      name                          = string
      subnet_id                     = string           # Must be GatewaySubnet
      public_ip_address_id          = string
      private_ip_address_allocation = optional(string, "Dynamic")
    })
    second_ip_configuration = optional(object({
      name                          = string
      public_ip_address_id          = string
      private_ip_address_allocation = optional(string, "Dynamic")
    }), null)                                          # For active-active; uses same subnet_id as primary
    bgp_settings = optional(object({
      asn = number
    }), null)
    local_network_gateways = optional(map(object({
      name            = string
      gateway_address = optional(string, null)
      gateway_fqdn    = optional(string, null)
      address_space   = optional(list(string), [])
      bgp_settings = optional(object({
        asn                 = number
        bgp_peering_address = string
      }), null)
    })), {})
    connections = optional(map(object({
      name                            = string
      type                            = string         # "IPsec", "Vnet2Vnet", "ExpressRoute"
      local_network_gateway_key       = optional(string, null)
      peer_virtual_network_gateway_id = optional(string, null)
      express_route_circuit_id        = optional(string, null)
      shared_key                      = optional(string, null)
      enable_bgp                      = optional(bool, false)
      routing_weight                  = optional(number, null)
      connection_protocol             = optional(string, "IKEv2")
      ipsec_policy = optional(object({
        dh_group         = string
        ike_encryption   = string
        ike_integrity    = string
        ipsec_encryption = string
        ipsec_integrity  = string
        pfs_group        = string
        sa_lifetime      = optional(number, 27000)
        sa_datasize      = optional(number, 102400000)
      }), null)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for gw_key, gw in var.vpn_gateways : [
        for conn_key, conn in gw.connections :
        conn.ipsec_policy == null ? true : !contains(["DES", "DES3"], conn.ipsec_policy.ike_encryption)
      ]
    ]))
    error_message = "ike_encryption must not be DES or DES3. Use a strong encryption algorithm such as AES256 or GCMAES256."
  }

  validation {
    condition = alltrue(flatten([
      for gw_key, gw in var.vpn_gateways : [
        for conn_key, conn in gw.connections :
        conn.ipsec_policy == null ? true : !contains(["DES", "DES3", "None"], conn.ipsec_policy.ipsec_encryption)
      ]
    ]))
    error_message = "ipsec_encryption must not be DES, DES3, or None. Use a strong encryption algorithm such as AES256 or GCMAES256."
  }

  validation {
    condition = alltrue(flatten([
      for gw_key, gw in var.vpn_gateways : [
        for conn_key, conn in gw.connections :
        conn.ipsec_policy == null ? true : conn.ipsec_policy.ike_integrity != "MD5"
      ]
    ]))
    error_message = "ike_integrity must not be MD5. Use a strong integrity algorithm such as SHA256 or GCMAES256."
  }

  validation {
    condition = alltrue(flatten([
      for gw_key, gw in var.vpn_gateways : [
        for conn_key, conn in gw.connections :
        conn.ipsec_policy == null ? true : conn.ipsec_policy.ipsec_integrity != "MD5"
      ]
    ]))
    error_message = "ipsec_integrity must not be MD5. Use a strong integrity algorithm such as SHA256 or GCMAES256."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------
# Optional: Internal utility module variables
# Uncomment to enable naming, tagging, diagnostics, and budget
# enforcement within this module.
# -----------------------------------------------------------------

# variable "naming_config" {
#   description = "Configuration for the az-naming module. Set to null to disable."
#   type = object({
#     environment = string
#     region      = string
#     workload    = string
#   })
#   default = null
# }

# variable "tagging_config" {
#   description = "Configuration for the az-tagging module. Set to null to use var.tags directly."
#   type = object({
#     environment         = string
#     owner               = string
#     cost_center         = string
#     project             = string
#     data_classification = optional(string, "internal")
#   })
#   default = null
# }

# variable "diagnostics_config" {
#   description = "Configuration for the az-diagnostics module. Set to null to disable."
#   type = object({
#     log_analytics_workspace_id = string
#     storage_account_id         = optional(string, null)
#   })
#   default = null
# }

# variable "budget_config" {
#   description = "Configuration for the az-budget module. Set to null to disable."
#   type = object({
#     amount             = number
#     resource_group_id  = string
#     start_date         = string
#     contact_emails     = list(string)
#   })
#   default = null
# }
