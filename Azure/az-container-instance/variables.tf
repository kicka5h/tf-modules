variable "resource_group_name" {
  description = "Name of the resource group to create container groups in"
  type        = string
}

variable "location" {
  description = "Azure region for all container groups"
  type        = string
}

variable "container_groups" {
  description = "Map of container groups to create. Key is a logical name, value defines the container group and its containers."
  type = map(object({
    name            = string
    os_type         = optional(string, "Linux")
    restart_policy  = optional(string, "Always") # "Always", "OnFailure", "Never"
    ip_address_type = optional(string, "Private") # "Public" or "Private"
    subnet_ids      = optional(list(string), [])  # required when Private
    dns_name_label  = optional(string, null)
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })
    containers = map(object({
      name   = string
      image  = string
      cpu    = number
      memory = number
      ports = optional(list(object({
        port     = number
        protocol = optional(string, "TCP")
      })), [])
      environment_variables        = optional(map(string), {})
      secure_environment_variables = optional(map(string), {})
      commands                     = optional(list(string), [])
      volume = optional(list(object({
        name                 = string
        mount_path           = string
        read_only            = optional(bool, false)
        storage_account_name = optional(string, null)
        storage_account_key  = optional(string, null)
        share_name           = optional(string, null)
      })), [])
    }))
    image_registry_credential = optional(list(object({
      server                    = string
      username                  = optional(string, null)
      password                  = optional(string, null)
      user_assigned_identity_id = optional(string, null)
    })), [])
    dns_config = optional(object({
      nameservers = list(string)
    }), null)
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, cg in var.container_groups :
      contains(["Linux", "Windows"], cg.os_type)
    ])
    error_message = "Each container group must have os_type set to one of: Linux, Windows."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
