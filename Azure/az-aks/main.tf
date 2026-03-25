locals {
  default_tags = {
    Terraform = "true"
  }
  tags = merge(local.default_tags, var.tags)

  # Flatten additional node pools into a map for for_each
  additional_node_pools = {
    for item in flatten([
      for cluster_key, cluster in var.aks_clusters : [
        for pool_key, pool in cluster.additional_node_pools : {
          key         = "${cluster_key}-${pool_key}"
          cluster_key = cluster_key
          pool_key    = pool_key
          name                = pool.name
          vm_size             = pool.vm_size
          node_count          = pool.node_count
          min_count           = pool.min_count
          max_count           = pool.max_count
          enable_auto_scaling = pool.enable_auto_scaling
          zones               = pool.zones
          vnet_subnet_id      = pool.vnet_subnet_id
          max_pods            = pool.max_pods
          os_disk_size_gb     = pool.os_disk_size_gb
          os_disk_type        = pool.os_disk_type
          os_type             = pool.os_type
          mode                = pool.mode
          node_labels         = pool.node_labels
          node_taints         = pool.node_taints
          tags                = pool.tags
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  for_each = var.aks_clusters

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = each.value.dns_prefix
  kubernetes_version  = each.value.kubernetes_version
  sku_tier            = each.value.sku_tier

  private_cluster_enabled = each.value.private_cluster_enabled
  private_dns_zone_id     = each.value.private_dns_zone_id

  role_based_access_control_enabled = each.value.role_based_access_control_enabled

  automatic_upgrade_channel = each.value.automatic_upgrade_channel

  tags = merge(local.tags, each.value.tags)

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.type == "UserAssigned" ? each.value.identity.identity_ids : []
  }

  default_node_pool {
    name                         = each.value.default_node_pool.name
    vm_size                      = each.value.default_node_pool.vm_size
    node_count                   = each.value.default_node_pool.node_count
    min_count                    = each.value.default_node_pool.min_count
    max_count                    = each.value.default_node_pool.max_count
    enable_auto_scaling          = each.value.default_node_pool.enable_auto_scaling
    zones                        = each.value.default_node_pool.zones
    vnet_subnet_id               = each.value.default_node_pool.vnet_subnet_id
    max_pods                     = each.value.default_node_pool.max_pods
    os_disk_size_gb              = each.value.default_node_pool.os_disk_size_gb
    os_disk_type                 = each.value.default_node_pool.os_disk_type
    only_critical_addons_enabled = each.value.default_node_pool.only_critical_addons_enabled
    temporary_name_for_rotation  = each.value.default_node_pool.temporary_name_for_rotation
    node_labels                  = each.value.default_node_pool.node_labels
    node_taints                  = each.value.default_node_pool.node_taints
    tags                         = merge(local.tags, each.value.tags, each.value.default_node_pool.tags)
  }

  dynamic "network_profile" {
    for_each = each.value.network_profile != null ? [each.value.network_profile] : []
    content {
      network_plugin    = network_profile.value.network_plugin
      network_policy    = network_profile.value.network_policy
      dns_service_ip    = network_profile.value.dns_service_ip
      service_cidr      = network_profile.value.service_cidr
      load_balancer_sku = network_profile.value.load_balancer_sku
      outbound_type     = network_profile.value.outbound_type
    }
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = each.value.azure_active_directory_role_based_access_control != null ? [each.value.azure_active_directory_role_based_access_control] : []
    content {
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
    }
  }

  dynamic "oms_agent" {
    for_each = each.value.oms_agent != null ? [each.value.oms_agent] : []
    content {
      log_analytics_workspace_id = oms_agent.value.log_analytics_workspace_id
    }
  }

  dynamic "microsoft_defender" {
    for_each = each.value.microsoft_defender != null ? [each.value.microsoft_defender] : []
    content {
      log_analytics_workspace_id = microsoft_defender.value.log_analytics_workspace_id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = each.value.key_vault_secrets_provider != null ? [each.value.key_vault_secrets_provider] : []
    content {
      secret_rotation_enabled  = key_vault_secrets_provider.value.secret_rotation_enabled
      secret_rotation_interval = key_vault_secrets_provider.value.secret_rotation_interval
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = local.additional_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this[each.value.cluster_key].id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  enable_auto_scaling   = each.value.enable_auto_scaling
  zones                 = each.value.zones
  vnet_subnet_id        = each.value.vnet_subnet_id
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_type               = each.value.os_type
  mode                  = each.value.mode
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  tags                  = merge(local.tags, var.aks_clusters[each.value.cluster_key].tags, each.value.tags)
}
