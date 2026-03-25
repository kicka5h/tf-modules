variable "resource_group_name" {
  description = "Name of the resource group to create storage accounts in"
  type        = string
}

variable "location" {
  description = "Azure region for all storage accounts"
  type        = string
}

variable "storage_accounts" {
  description = "Map of storage accounts to create. Key is a logical name, value defines the storage account and its sub-resources."
  type = map(object({
    name                     = string
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "GRS")
    account_kind             = optional(string, "StorageV2")
    access_tier              = optional(string, "Hot")
    # Enforce: HTTPS only
    enable_https_traffic_only = optional(bool, true)
    # Enforce: minimum TLS 1.2
    min_tls_version = optional(string, "TLS1_2")
    # Enforce: no public blob access
    allow_nested_items_to_be_public = optional(bool, false)
    # Enforce: shared key access disabled (use AAD)
    shared_access_key_enabled = optional(bool, false)
    # Enforce: public network access disabled
    public_network_access_enabled = optional(bool, false)
    # Enforce: infrastructure encryption
    infrastructure_encryption_enabled = optional(bool, true)
    # Network rules
    network_rules = optional(object({
      default_action             = optional(string, "Deny")
      bypass                     = optional(list(string), ["AzureServices"])
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), null)
    # Blob properties
    blob_properties = optional(object({
      versioning_enabled       = optional(bool, true)
      change_feed_enabled      = optional(bool, true)
      last_access_time_enabled = optional(bool, false)
      delete_retention_policy = optional(object({
        days = optional(number, 30)
      }), { days = 30 })
      container_delete_retention_policy = optional(object({
        days = optional(number, 30)
      }), { days = 30 })
    }), {})
    # Customer-managed key encryption
    customer_managed_key = optional(object({
      key_vault_key_id          = string
      user_assigned_identity_id = string
    }), null)
    # Identity
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })
    # Sub-resources
    containers = optional(map(object({
      name                  = string
      container_access_type = optional(string, "private")
    })), {})
    file_shares = optional(map(object({
      name  = string
      quota = optional(number, 50)
    })), {})
    queues = optional(map(object({
      name = string
    })), {})
    tables = optional(map(object({
      name = string
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, sa in var.storage_accounts :
      sa.min_tls_version == "TLS1_2"
    ])
    error_message = "All storage accounts must use TLS 1.2 (min_tls_version = TLS1_2)."
  }

  validation {
    condition = alltrue([
      for k, sa in var.storage_accounts :
      sa.enable_https_traffic_only == true
    ])
    error_message = "All storage accounts must enforce HTTPS only (enable_https_traffic_only = true)."
  }

  validation {
    condition = alltrue([
      for k, sa in var.storage_accounts :
      sa.public_network_access_enabled == false
    ])
    error_message = "All storage accounts must have public network access disabled (public_network_access_enabled = false)."
  }

  validation {
    condition = alltrue([
      for k, sa in var.storage_accounts :
      sa.shared_access_key_enabled == false
    ])
    error_message = "All storage accounts must have shared access key disabled (shared_access_key_enabled = false). Use Azure AD authentication."
  }

  validation {
    condition = alltrue([
      for k, sa in var.storage_accounts :
      sa.allow_nested_items_to_be_public == false
    ])
    error_message = "All storage accounts must have public blob access disabled (allow_nested_items_to_be_public = false)."
  }

  validation {
    condition = alltrue([
      for k, sa in var.storage_accounts :
      sa.infrastructure_encryption_enabled == true
    ])
    error_message = "All storage accounts must have infrastructure encryption enabled (infrastructure_encryption_enabled = true)."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
