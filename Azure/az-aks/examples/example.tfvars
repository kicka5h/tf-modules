resource_group_name = "rg-aks-production"
location            = "eastus2"

aks_clusters = {
  prod = {
    name                    = "aks-prod"
    dns_prefix              = "aksprod"
    kubernetes_version      = "1.29"
    sku_tier                = "Standard"
    private_cluster_enabled = true

    identity = {
      type = "SystemAssigned"
    }

    azure_active_directory_role_based_access_control = {
      admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
      azure_rbac_enabled     = true
    }

    default_node_pool = {
      name                         = "system"
      vm_size                      = "Standard_D4s_v5"
      min_count                    = 2
      max_count                    = 5
      enable_auto_scaling          = true
      zones                        = ["1", "2", "3"]
      vnet_subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-production/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/aks-system"
      max_pods                     = 30
      os_disk_size_gb              = 128
      os_disk_type                 = "Managed"
      only_critical_addons_enabled = true
      temporary_name_for_rotation  = "systemtmp"
      tags = {
        pool = "system"
      }
    }

    network_profile = {
      network_plugin    = "azure"
      network_policy    = "calico"
      dns_service_ip    = "10.2.0.10"
      service_cidr      = "10.2.0.0/16"
      load_balancer_sku = "standard"
      outbound_type     = "loadBalancer"
    }

    automatic_upgrade_channel = "stable"

    oms_agent = {
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-central"
    }

    key_vault_secrets_provider = {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }

    additional_node_pools = {
      workload = {
        name                = "workload"
        vm_size             = "Standard_D8s_v5"
        min_count           = 1
        max_count           = 20
        enable_auto_scaling = true
        zones               = ["1", "2", "3"]
        vnet_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-production/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/aks-workload"
        max_pods            = 30
        os_disk_size_gb     = 128
        os_disk_type        = "Managed"
        mode                = "User"
        node_labels = {
          workload = "general"
        }
        tags = {
          pool = "workload"
        }
      }
    }

    tags = {
      environment = "production"
      team        = "platform"
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
