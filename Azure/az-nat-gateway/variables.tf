variable "resource_group_name" {
  description = "Name of the resource group to create NAT gateways in"
  type        = string
}

variable "location" {
  description = "Azure region for all NAT gateways"
  type        = string
}

variable "nat_gateways" {
  description = "Map of NAT gateways to create. Key is a logical name, value defines the gateway and its associations."
  type = map(object({
    name                    = string
    sku_name                = optional(string, "Standard")
    idle_timeout_in_minutes = optional(number, 4)
    zones                   = optional(list(string), [])
    public_ip_ids           = optional(list(string), [])
    public_ip_prefix_ids    = optional(list(string), [])
    subnet_ids              = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for gw_key, gw in var.nat_gateways :
      contains(["Standard"], gw.sku_name)
    ])
    error_message = "Each NAT gateway must have sku_name set to: Standard."
  }

  validation {
    condition = alltrue([
      for gw_key, gw in var.nat_gateways :
      gw.idle_timeout_in_minutes >= 4 && gw.idle_timeout_in_minutes <= 120
    ])
    error_message = "Each NAT gateway idle_timeout_in_minutes must be between 4 and 120."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
