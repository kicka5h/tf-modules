variable "resource_group_name" {
  description = "Name of the resource group to create private endpoints in"
  type        = string
}

variable "location" {
  description = "Azure region for all private endpoints"
  type        = string
}

variable "private_endpoints" {
  description = "Map of private endpoints to create. Key is a logical name, value defines the endpoint configuration."
  type = map(object({
    name      = string
    subnet_id = string
    private_service_connection = object({
      name                           = string
      private_connection_resource_id = string
      subresource_names              = optional(list(string), [])
      is_manual_connection           = optional(bool, false)
      request_message                = optional(string, null)
    })
    private_dns_zone_group = optional(object({
      name                 = string
      private_dns_zone_ids = list(string)
    }), null)
    ip_configuration = optional(list(object({
      name               = string
      private_ip_address  = string
      subresource_name   = optional(string, null)
      member_name        = optional(string, null)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.private_endpoints : v.private_dns_zone_group != null
    ])
    error_message = "Each private endpoint must have a private_dns_zone_group configured. Omitting DNS zone group is a common misconfiguration that prevents private DNS resolution."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
