variable "resource_group_name" {
  description = "Name of the resource group to create public IPs in"
  type        = string
}

variable "location" {
  description = "Azure region for all public IPs"
  type        = string
}

variable "public_ips" {
  description = "Map of public IPs to create. Key is a logical name, value defines the public IP configuration."
  type = map(object({
    name                    = string
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    zones                   = optional(list(string), [])
    ip_version              = optional(string, "IPv4")
    idle_timeout_in_minutes = optional(number, 4)
    domain_name_label       = optional(string, null)
    reverse_fqdn            = optional(string, null)
    ip_tags                 = optional(map(string), {})
    public_ip_prefix_id     = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.public_ips : contains(["Static", "Dynamic"], v.allocation_method)
    ])
    error_message = "allocation_method must be \"Static\" or \"Dynamic\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.public_ips : contains(["Basic", "Standard"], v.sku)
    ])
    error_message = "sku must be \"Basic\" or \"Standard\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.public_ips : contains(["Regional", "Global"], v.sku_tier)
    ])
    error_message = "sku_tier must be \"Regional\" or \"Global\"."
  }
}

variable "public_ip_prefixes" {
  description = "Map of public IP prefixes to create. Key is a logical name, value defines the prefix configuration."
  type = map(object({
    name          = string
    sku           = optional(string, "Standard")
    prefix_length = number
    zones         = optional(list(string), [])
    ip_version    = optional(string, "IPv4")
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
