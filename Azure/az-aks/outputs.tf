output "aks_clusters" {
  description = "Map of AKS clusters created, keyed by the logical name"
  value = {
    for k, v in azurerm_kubernetes_cluster.this : k => {
      id                  = v.id
      name                = v.name
      kube_config_raw     = v.kube_config_raw
      fqdn                = v.fqdn
      private_fqdn        = v.private_fqdn
      node_resource_group = v.node_resource_group
      identity_principal_id = try(v.identity[0].principal_id, null)
    }
  }
  sensitive = true
}

output "additional_node_pools" {
  description = "Map of additional node pools created, keyed by cluster-pool logical name"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.this : k => {
      id   = v.id
      name = v.name
    }
  }
}
