# az-container-registry

Creates and manages Azure Container Registries with enforced security defaults, geo-replication, customer-managed encryption, and identity configuration.

## Usage

```hcl
module "acr" {
  source              = "../az-container-registry"
  resource_group_name = "rg-containers"
  location            = "eastus2"

  container_registries = {
    main = {
      name = "crproductionmain"
      georeplications = {
        westus2 = {
          location                = "westus2"
          zone_redundancy_enabled = true
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

### SKU

| What | Variable Path | Valid Values |
| --- | --- | --- |
| SKU tier | `container_registries.<key>.sku` | `"Basic"`, `"Standard"`, `"Premium"` (default: `"Premium"`) |

Premium is the default and is required for private endpoints, zone redundancy, geo-replication, content trust, and retention policies.

### Admin Access

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Admin user | `container_registries.<key>.admin_enabled` | `false` (enforced, validation rejects `true`) |

### Networking

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Public network access | `container_registries.<key>.public_network_access_enabled` | `true`, `false` (default: `false`) |
| Network rule bypass | `container_registries.<key>.network_rule_bypass_option` | `"AzureServices"`, `"None"` (default: `"AzureServices"`) |

### Zone Redundancy

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Zone redundancy | `container_registries.<key>.zone_redundancy_enabled` | `true`, `false` (default: `true`) |

### Content Trust

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Trust policy (image signing) | `container_registries.<key>.trust_policy_enabled` | `true`, `false` (default: `true`) |

### Retention Policy

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Retention enabled | `container_registries.<key>.retention_policy.enabled` | `true`, `false` (default: `true`) |
| Retention days | `container_registries.<key>.retention_policy.days` | Number of days (default: `30`) |

Only available on Premium SKU.

### Georeplications

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Location | `container_registries.<key>.georeplications.<name>.location` | Any Azure region |
| Zone redundancy | `container_registries.<key>.georeplications.<name>.zone_redundancy_enabled` | `true`, `false` (default: `true`) |
| Tags | `container_registries.<key>.georeplications.<name>.tags` | `map(string)` |

### Encryption

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Key Vault key ID | `container_registries.<key>.encryption.key_vault_key_id` | Key Vault key resource ID |
| Identity client ID | `container_registries.<key>.encryption.identity_client_id` | User-assigned identity client ID |

### Identity

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Identity type | `container_registries.<key>.identity.type` | `"SystemAssigned"`, `"UserAssigned"`, `"SystemAssigned, UserAssigned"` (default: `"SystemAssigned"`) |
| Identity IDs | `container_registries.<key>.identity.identity_ids` | List of user-assigned identity resource IDs |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |
| Per-registry tags | `container_registries.<key>.tags` | `map(string)`, merged with module-level tags |

## Enforced Policies

- **Premium SKU default**: All registries default to Premium SKU, enabling private endpoints, zone redundancy, geo-replication, content trust, and retention policies.
- **Admin user disabled**: Validation rejects any registry with `admin_enabled = true`. Use RBAC or service principals for authentication.
- **Public network access disabled**: Registries are not publicly accessible by default. Use private endpoints for connectivity.
- **Zone redundancy enabled**: Registries are zone-redundant by default for high availability.
- **Content trust enabled**: Image signing (trust policy) is enabled by default.
- **Retention policy**: Untagged manifests are automatically purged after 30 days by default.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Deletion protection**: OPA policy denies deletion or replacement of container registries in CI/CD pipelines.
