variable "resource_group_name" {
  description = "Name of the resource group to create AKS clusters in"
  type        = string
}

variable "location" {
  description = "Azure region for all AKS clusters"
  type        = string
}

variable "aks_clusters" {
  description = "Map of AKS clusters to create. Key is a logical name, value defines the cluster and its node pools."
  type = map(object({
    name               = string
    dns_prefix         = string
    kubernetes_version = optional(string, null)
    sku_tier           = optional(string, "Standard") # "Free", "Standard", "Premium"
    # Enforce: private cluster
    private_cluster_enabled = optional(bool, true)
    private_dns_zone_id     = optional(string, null)
    # Enforce: RBAC
    role_based_access_control_enabled = optional(bool, true)
    azure_active_directory_role_based_access_control = optional(object({
      admin_group_object_ids = optional(list(string), [])
      azure_rbac_enabled     = optional(bool, true)
    }), null)
    # Enforce: system-assigned identity
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })
    # Default node pool (required)
    default_node_pool = object({
      name                         = string
      vm_size                      = string
      node_count                   = optional(number, null)
      min_count                    = optional(number, null)
      max_count                    = optional(number, null)
      enable_auto_scaling          = optional(bool, true)
      zones                        = optional(list(string), ["1", "2", "3"])
      vnet_subnet_id               = string
      max_pods                     = optional(number, 30)
      os_disk_size_gb              = optional(number, 128)
      os_disk_type                 = optional(string, "Managed")
      only_critical_addons_enabled = optional(bool, false)
      temporary_name_for_rotation  = optional(string, null)
      node_labels                  = optional(map(string), {})
      node_taints                  = optional(list(string), [])
      tags                         = optional(map(string), {})
    })
    # Enforce: network policy
    network_profile = optional(object({
      network_plugin    = optional(string, "azure")       # "azure" or "kubenet"
      network_policy    = optional(string, "calico")      # "calico", "azure", "cilium"
      dns_service_ip    = optional(string, null)
      service_cidr      = optional(string, null)
      load_balancer_sku = optional(string, "standard")
      outbound_type     = optional(string, "loadBalancer")
    }), {})
    # Enforce: auto-upgrade
    automatic_upgrade_channel = optional(string, "stable") # "none", "patch", "rapid", "stable", "node-image"
    # Azure Monitor / logging
    oms_agent = optional(object({
      log_analytics_workspace_id = string
    }), null)
    # Microsoft Defender
    microsoft_defender = optional(object({
      log_analytics_workspace_id = string
    }), null)
    # Key Vault Secrets Provider
    key_vault_secrets_provider = optional(object({
      secret_rotation_enabled  = optional(bool, true)
      secret_rotation_interval = optional(string, "2m")
    }), null)
    # Additional node pools
    additional_node_pools = optional(map(object({
      name                = string
      vm_size             = string
      node_count          = optional(number, null)
      min_count           = optional(number, null)
      max_count           = optional(number, null)
      enable_auto_scaling = optional(bool, true)
      zones               = optional(list(string), ["1", "2", "3"])
      vnet_subnet_id      = optional(string, null)
      max_pods            = optional(number, 30)
      os_disk_size_gb     = optional(number, 128)
      os_disk_type        = optional(string, "Managed")
      os_type             = optional(string, "Linux")
      mode                = optional(string, "User") # "System" or "User"
      node_labels         = optional(map(string), {})
      node_taints         = optional(list(string), [])
      tags                = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, c in var.aks_clusters :
      contains(["Free", "Standard", "Premium"], c.sku_tier)
    ])
    error_message = "Each AKS cluster must have sku_tier set to one of: Free, Standard, Premium."
  }

  validation {
    condition = alltrue([
      for k, c in var.aks_clusters :
      c.role_based_access_control_enabled == true
    ])
    error_message = "RBAC must be enabled on all AKS clusters (role_based_access_control_enabled = true)."
  }
}

variable "tags" {
  description = "Tags to apply to all resources. Merged with default tags."
  type        = map(string)
  default     = {}
}
