# az-container-instance

Creates and manages Azure Container Instances (container groups) with VNet integration, managed identity, and configurable containers.

## Usage

```hcl
module "aci" {
  source              = "../az-container-instance"
  resource_group_name = "rg-containers"
  location            = "eastus2"

  container_groups = {
    web = {
      name            = "cg-web"
      ip_address_type = "Private"
      subnet_ids      = [module.vnet.subnets["main-containers"].id]

      containers = {
        nginx = {
          name   = "nginx"
          image  = "nginx:1.25"
          cpu    = 0.5
          memory = 1.0
          ports  = [{ port = 80, protocol = "TCP" }]
        }
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Configuration Reference

### Container Groups

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Name | `container_groups.<key>.name` | Resource name string |
| OS type | `container_groups.<key>.os_type` | `"Linux"` (default), `"Windows"` |
| Restart policy | `container_groups.<key>.restart_policy` | `"Always"` (default), `"OnFailure"`, `"Never"` |
| IP address type | `container_groups.<key>.ip_address_type` | `"Private"` (default), `"Public"` |
| Subnet IDs | `container_groups.<key>.subnet_ids` | List of subnet resource IDs (required when Private) |
| DNS name label | `container_groups.<key>.dns_name_label` | String (Public IP only) |
| Per-group tags | `container_groups.<key>.tags` | `map(string)`, merged with module and default tags |

### Containers

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Name | `container_groups.<key>.containers.<key>.name` | Container name string |
| Image | `container_groups.<key>.containers.<key>.image` | Container image reference |
| CPU | `container_groups.<key>.containers.<key>.cpu` | CPU cores (e.g., `0.5`, `1.0`) |
| Memory | `container_groups.<key>.containers.<key>.memory` | Memory in GB (e.g., `0.5`, `1.5`) |
| Ports | `container_groups.<key>.containers.<key>.ports` | List of `{ port, protocol }` |
| Env vars | `container_groups.<key>.containers.<key>.environment_variables` | `map(string)` |
| Secure env vars | `container_groups.<key>.containers.<key>.secure_environment_variables` | `map(string)` (sensitive) |
| Commands | `container_groups.<key>.containers.<key>.commands` | List of command strings |

### Volumes

| What | Variable Path | Notes |
| --- | --- | --- |
| Name | `containers.<key>.volume[*].name` | Volume name |
| Mount path | `containers.<key>.volume[*].mount_path` | Path inside container |
| Read only | `containers.<key>.volume[*].read_only` | `bool`, default `false` |
| Storage account | `containers.<key>.volume[*].storage_account_name` | For Azure File shares |
| Storage key | `containers.<key>.volume[*].storage_account_key` | For Azure File shares |
| Share name | `containers.<key>.volume[*].share_name` | Azure File share name |

### Identity

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Type | `container_groups.<key>.identity.type` | `"SystemAssigned"` (default), `"UserAssigned"`, `"SystemAssigned, UserAssigned"` |
| Identity IDs | `container_groups.<key>.identity.identity_ids` | List of user-assigned identity resource IDs |

### Registry Credentials

| What | Variable Path | Notes |
| --- | --- | --- |
| Server | `container_groups.<key>.image_registry_credential[*].server` | Registry FQDN (e.g., `myacr.azurecr.io`) |
| Username | `container_groups.<key>.image_registry_credential[*].username` | Registry username |
| Password | `container_groups.<key>.image_registry_credential[*].password` | Registry password |
| Managed identity | `container_groups.<key>.image_registry_credential[*].user_assigned_identity_id` | User-assigned identity ID for ACR pull |

### Networking

| What | Variable Path | Notes |
| --- | --- | --- |
| IP type | `container_groups.<key>.ip_address_type` | `"Private"` (default) for VNet integration |
| Subnet IDs | `container_groups.<key>.subnet_ids` | Required when `ip_address_type = "Private"` |
| DNS config | `container_groups.<key>.dns_config.nameservers` | List of DNS server IPs |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |
| Per-group tags | `container_groups.<key>.tags` | `map(string)`, merged on top of module tags |

## Enforced Policies

- **Private IP enforced**: Container groups must use `ip_address_type = "Private"`. This is validated at plan time; setting `"Public"` will be rejected. VNet integration via `subnet_ids` is required.
- **Managed identity by default**: Every container group gets a `SystemAssigned` identity unless overridden. This avoids storing credentials for Azure service access.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **OS type validation**: Only `"Linux"` and `"Windows"` are accepted; invalid values are rejected at plan time.
- **Deletion/replacement protection**: OPA policy denies `terraform plan` operations that would delete or replace a container group. Request an exception to override.
