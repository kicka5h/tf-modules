variable "resource_group_name" {
  description = "Name of the resource group to create VNets in"
  type        = string
}

variable "location" {
  description = "Azure region for all VNets"
  type        = string
}

variable "vnets" {
  description = "Map of VNets to create. Key is a logical name, value defines the VNet and its subnets."
  type = map(object({
    name                    = string
    address_space           = list(string)
    dns_servers             = optional(list(string), [])
    flow_timeout_in_minutes = optional(number, null)
    ddos_protection_plan = optional(object({
      id     = string
      enable = bool
    }), null)
    encryption = optional(object({
      enforcement = string # "DropUnencrypted" or "AllowUnencrypted"
    }), null)
    subnets = optional(map(object({
      address_prefixes                          = list(string)
      service_endpoints                         = optional(list(string), [])
      private_endpoint_network_policies         = optional(string, "Disabled")
      private_link_service_network_policies_enabled = optional(bool, false)
      delegation = optional(object({
        name = string
        service_delegation = object({
          name    = string
          actions = optional(list(string), [])
        })
      }), null)
    })), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
