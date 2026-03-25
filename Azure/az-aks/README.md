# az-aks

Creates and manages Azure Kubernetes Service (AKS) clusters with caller-defined node pools, enforced security defaults, and optional monitoring integrations.

## Usage

```hcl
module "aks" {
  source              = "../az-aks"
  resource_group_name = "rg-aks-production"
  location            = "eastus2"

  aks_clusters = {
    prod = {
      name       = "aks-prod"
      dns_prefix = "aksprod"
      sku_tier   = "Standard"
      default_node_pool = {
        name           = "system"
        vm_size        = "Standard_D4s_v5"
        min_count      = 2
        max_count      = 5
        vnet_subnet_id = module.vnet.subnets["aks-system"].id
      }
      network_profile = {
        network_plugin = "azure"
        network_policy = "calico"
      }
      additional_node_pools = {
        workload = {
          name           = "workload"
          vm_size        = "Standard_D8s_v5"
          min_count      = 1
          max_count      = 20
          vnet_subnet_id = module.vnet.subnets["aks-workload"].id
          mode           = "User"
        }
      }
    }
  }

  tags = {
    environment = "production"
  }
}
```

## Configuration Reference

### Cluster Settings

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Cluster name | `aks_clusters.<key>.name` | Any valid AKS name |
| DNS prefix | `aks_clusters.<key>.dns_prefix` | Unique DNS prefix |
| Kubernetes version | `aks_clusters.<key>.kubernetes_version` | Version string or `null` (latest) |
| SKU tier | `aks_clusters.<key>.sku_tier` | `"Free"`, `"Standard"`, `"Premium"` |
| Private cluster | `aks_clusters.<key>.private_cluster_enabled` | `true` (default), `false` |
| Private DNS zone | `aks_clusters.<key>.private_dns_zone_id` | Resource ID or `null` |
| Auto-upgrade channel | `aks_clusters.<key>.automatic_upgrade_channel` | `"none"`, `"patch"`, `"rapid"`, `"stable"` (default), `"node-image"` |
| Per-cluster tags | `aks_clusters.<key>.tags` | `map(string)` |

### Identity

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Identity type | `aks_clusters.<key>.identity.type` | `"SystemAssigned"` (default), `"UserAssigned"` |
| User-assigned IDs | `aks_clusters.<key>.identity.identity_ids` | List of identity resource IDs |

### RBAC / Azure AD

| What | Variable Path | Valid Values |
| --- | --- | --- |
| RBAC enabled | `aks_clusters.<key>.role_based_access_control_enabled` | `true` (required, validated) |
| Azure RBAC enabled | `aks_clusters.<key>.azure_active_directory_role_based_access_control.azure_rbac_enabled` | `true` (default), `false` |
| Admin group IDs | `aks_clusters.<key>.azure_active_directory_role_based_access_control.admin_group_object_ids` | List of AAD group object IDs |

### Default Node Pool

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Pool name | `aks_clusters.<key>.default_node_pool.name` | Short alphanumeric name |
| VM size | `aks_clusters.<key>.default_node_pool.vm_size` | Azure VM SKU |
| Node count | `aks_clusters.<key>.default_node_pool.node_count` | Number or `null` |
| Min/max count | `aks_clusters.<key>.default_node_pool.min_count` / `max_count` | Numbers (for autoscaling) |
| Auto-scaling | `aks_clusters.<key>.default_node_pool.enable_auto_scaling` | `true` (default), `false` |
| Availability zones | `aks_clusters.<key>.default_node_pool.zones` | `["1", "2", "3"]` (default) |
| Subnet | `aks_clusters.<key>.default_node_pool.vnet_subnet_id` | Subnet resource ID |
| Max pods | `aks_clusters.<key>.default_node_pool.max_pods` | `30` (default) |
| OS disk size | `aks_clusters.<key>.default_node_pool.os_disk_size_gb` | `128` (default) |
| OS disk type | `aks_clusters.<key>.default_node_pool.os_disk_type` | `"Managed"` (default), `"Ephemeral"` |
| Critical addons only | `aks_clusters.<key>.default_node_pool.only_critical_addons_enabled` | `true`, `false` (default) |
| Node labels | `aks_clusters.<key>.default_node_pool.node_labels` | `map(string)` |
| Node taints | `aks_clusters.<key>.default_node_pool.node_taints` | List of taint strings |

### Additional Node Pools

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Pool name | `aks_clusters.<key>.additional_node_pools.<pool>.name` | Short alphanumeric name |
| VM size | `aks_clusters.<key>.additional_node_pools.<pool>.vm_size` | Azure VM SKU |
| Mode | `aks_clusters.<key>.additional_node_pools.<pool>.mode` | `"User"` (default), `"System"` |
| OS type | `aks_clusters.<key>.additional_node_pools.<pool>.os_type` | `"Linux"` (default), `"Windows"` |
| Subnet | `aks_clusters.<key>.additional_node_pools.<pool>.vnet_subnet_id` | Subnet resource ID or `null` |

All other node pool settings (autoscaling, zones, max_pods, disk, labels, taints, tags) follow the same pattern as the default node pool.

### Networking

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Network plugin | `aks_clusters.<key>.network_profile.network_plugin` | `"azure"` (default), `"kubenet"` |
| Network policy | `aks_clusters.<key>.network_profile.network_policy` | `"calico"` (default), `"azure"`, `"cilium"` |
| DNS service IP | `aks_clusters.<key>.network_profile.dns_service_ip` | IP address or `null` |
| Service CIDR | `aks_clusters.<key>.network_profile.service_cidr` | CIDR or `null` |
| Load balancer SKU | `aks_clusters.<key>.network_profile.load_balancer_sku` | `"standard"` (default), `"basic"` |
| Outbound type | `aks_clusters.<key>.network_profile.outbound_type` | `"loadBalancer"` (default), `"userDefinedRouting"`, `"managedNATGateway"`, `"userAssignedNATGateway"` |

### Monitoring

| What | Variable Path | Notes |
| --- | --- | --- |
| OMS Agent | `aks_clusters.<key>.oms_agent.log_analytics_workspace_id` | Enables Container Insights |
| Microsoft Defender | `aks_clusters.<key>.microsoft_defender.log_analytics_workspace_id` | Enables Defender for Containers |
| Key Vault provider | `aks_clusters.<key>.key_vault_secrets_provider` | Enables CSI Secrets Store driver |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Global tags | `tags` | `map(string)`, merged with default tags |
| Per-cluster tags | `aks_clusters.<key>.tags` | Merged with global + default tags |
| Per-pool tags | `aks_clusters.<key>.default_node_pool.tags` / `additional_node_pools.<pool>.tags` | Merged with cluster + global + default tags |

## Enforced Policies

- **Private cluster**: `private_cluster_enabled` defaults to `true`. All clusters are private by default.
- **RBAC required**: `role_based_access_control_enabled` must be `true`. Validated at plan time; setting it to `false` is rejected.
- **Network policy**: `network_profile.network_policy` defaults to `"calico"`. Every cluster gets a network policy enforced.
- **System-assigned identity**: `identity.type` defaults to `"SystemAssigned"`. All clusters use managed identity by default.
- **Auto-upgrade**: `automatic_upgrade_channel` defaults to `"stable"`. Clusters receive automatic upgrades.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **OPA policy**: A Rego policy in `policies/` denies deletion or replacement of `azurerm_kubernetes_cluster` resources at plan time.
