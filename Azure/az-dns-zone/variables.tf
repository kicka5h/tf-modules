variable "resource_group_name" {
  description = "Name of the resource group to create DNS zones in"
  type        = string
}

variable "dns_zones" {
  description = "Map of DNS zones to create. Key is a logical name, value defines the zone."
  type = map(object({
    name                     = string
    type                     = string # "public" or "private"
    vnet_links               = optional(map(object({
      virtual_network_id       = string
      registration_enabled     = optional(bool, false)
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.dns_zones : contains(["public", "private"], v.type)])
    error_message = "Each dns_zones entry must have type set to \"public\" or \"private\"."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
