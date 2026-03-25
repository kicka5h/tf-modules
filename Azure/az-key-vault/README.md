# az-key-vault

Creates and manages Azure Key Vaults with enforced security defaults, RBAC or access policy authorization, network ACLs, and purge protection.

## Usage

```hcl
module "key_vaults" {
  source              = "../az-key-vault"
  resource_group_name = "rg-security"
  location            = "eastus2"

  key_vaults = {
    main = {
      name = "kv-production-main"
      network_acls = {
        default_action = "Deny"
        bypass         = "AzureServices"
        ip_rules       = ["203.0.113.0/24"]
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
| SKU tier | `key_vaults.<key>.sku_name` | `"standard"`, `"premium"` (default: `"premium"`) |

Premium is the default, required for HSM-backed keys.

### Authorization

| What | Variable Path | Valid Values |
| --- | --- | --- |
| RBAC authorization | `key_vaults.<key>.enable_rbac_authorization` | `true`, `false` (default: `true`) |

RBAC is the default and recommended authorization model. Access policies are only created when `enable_rbac_authorization = false`.

### Soft Delete and Purge Protection

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Soft delete retention | `key_vaults.<key>.soft_delete_retention_days` | `7`-`90` (default: `90`) |
| Purge protection | `key_vaults.<key>.purge_protection_enabled` | `true` (enforced, validation rejects `false`) |

**WARNING:** Purge protection is enforced and cannot be disabled. When a vault with purge protection is deleted, the vault name is locked for the entire soft delete retention period (default 90 days). During this period, no new vault can be created with the same name. Plan vault naming carefully.

### Networking

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Public network access | `key_vaults.<key>.public_network_access_enabled` | `true`, `false` (default: `false`) |
| Network ACLs default action | `key_vaults.<key>.network_acls.default_action` | `"Allow"`, `"Deny"` (default: `"Deny"`) |
| Network ACLs bypass | `key_vaults.<key>.network_acls.bypass` | `"AzureServices"`, `"None"` (default: `"AzureServices"`) |
| IP rules | `key_vaults.<key>.network_acls.ip_rules` | List of CIDR ranges (default: `[]`) |
| Subnet IDs | `key_vaults.<key>.network_acls.virtual_network_subnet_ids` | List of subnet resource IDs (default: `[]`) |

### Deployment Access

| What | Variable Path | Valid Values |
| --- | --- | --- |
| VM deployment | `key_vaults.<key>.enabled_for_deployment` | `true`, `false` (default: `true`) |
| Disk encryption | `key_vaults.<key>.enabled_for_disk_encryption` | `true`, `false` (default: `true`) |
| Template deployment | `key_vaults.<key>.enabled_for_template_deployment` | `true`, `false` (default: `true`) |

### Access Policies

Access policies are only created when `enable_rbac_authorization = false`. If `tenant_id` is not specified on a policy, it defaults to the current Azure tenant.

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Object ID | `key_vaults.<key>.access_policies.<name>.object_id` | Azure AD object ID (required) |
| Tenant ID | `key_vaults.<key>.access_policies.<name>.tenant_id` | Azure AD tenant ID (default: current tenant) |
| Key permissions | `key_vaults.<key>.access_policies.<name>.key_permissions` | List of key permissions (default: `[]`) |
| Secret permissions | `key_vaults.<key>.access_policies.<name>.secret_permissions` | List of secret permissions (default: `[]`) |
| Certificate permissions | `key_vaults.<key>.access_policies.<name>.certificate_permissions` | List of certificate permissions (default: `[]`) |
| Storage permissions | `key_vaults.<key>.access_policies.<name>.storage_permissions` | List of storage permissions (default: `[]`) |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |
| Per-vault tags | `key_vaults.<key>.tags` | `map(string)`, merged with module-level tags |

## Enforced Policies

- **Premium SKU default**: All vaults default to premium SKU, enabling HSM-backed keys.
- **Purge protection enabled**: Validation rejects any vault with `purge_protection_enabled = false`. This is critical for compliance and prevents permanent data loss.
- **RBAC authorization default**: Vaults use Azure RBAC by default, which is the recommended authorization model over access policies.
- **Public network access disabled**: Vaults are not publicly accessible by default. Use private endpoints and network ACLs for connectivity.
- **Network ACLs default deny**: When network ACLs are configured, the default action is Deny with AzureServices bypass.
- **Soft delete 90 days**: Deleted vaults and their contents are retained for 90 days by default.
- **Deployment access enabled**: Vaults are accessible by VMs, disk encryption, and ARM templates by default.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Deletion protection**: OPA policy denies deletion or replacement of Key Vaults in CI/CD pipelines. This is CRITICAL because purge protection causes a 90-day lockout of the vault name on deletion.

## Purge Protection Warning

Purge protection is a one-way setting. Once enabled on a vault, it cannot be disabled. If a vault with purge protection is deleted (soft-deleted), the vault name is reserved for the duration of the soft delete retention period (default 90 days). No new vault can use the same name during this window, across any subscription in the same Azure AD tenant. This OPA policy blocks accidental deletions, but operators should still exercise caution when managing vault lifecycle.
