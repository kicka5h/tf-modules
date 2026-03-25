# az-storage-account

Creates and manages Azure Storage Accounts with enforced security defaults, sub-resources (blob containers, file shares, queues, tables), customer-managed encryption, and identity configuration.

## Usage

```hcl
module "storage" {
  source              = "../az-storage-account"
  resource_group_name = "rg-storage"
  location            = "eastus2"

  storage_accounts = {
    main = {
      name = "stprodmain001"
      containers = {
        data = {
          name = "data"
        }
      }
      file_shares = {
        config = {
          name  = "config"
          quota = 100
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

### Account Settings

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Account name | `storage_accounts.<key>.name` | Globally unique storage account name |
| Account tier | `storage_accounts.<key>.account_tier` | `"Standard"`, `"Premium"` (default: `"Standard"`) |
| Replication type | `storage_accounts.<key>.account_replication_type` | `"LRS"`, `"GRS"`, `"RAGRS"`, `"ZRS"`, `"GZRS"`, `"RAGZRS"` (default: `"GRS"`) |
| Account kind | `storage_accounts.<key>.account_kind` | `"StorageV2"`, `"BlobStorage"`, `"BlockBlobStorage"`, `"FileStorage"`, `"Storage"` (default: `"StorageV2"`) |
| Access tier | `storage_accounts.<key>.access_tier` | `"Hot"`, `"Cool"` (default: `"Hot"`) |

### Security

| What | Variable Path | Valid Values |
| --- | --- | --- |
| HTTPS only | `storage_accounts.<key>.enable_https_traffic_only` | `true` (enforced, validation rejects `false`) |
| Minimum TLS version | `storage_accounts.<key>.min_tls_version` | `"TLS1_2"` (enforced, validation rejects anything else) |
| Public blob access | `storage_accounts.<key>.allow_nested_items_to_be_public` | `false` (enforced, validation rejects `true`) |
| Shared access key | `storage_accounts.<key>.shared_access_key_enabled` | `false` (enforced, validation rejects `true`) |
| Public network access | `storage_accounts.<key>.public_network_access_enabled` | `false` (enforced, validation rejects `true`) |
| Infrastructure encryption | `storage_accounts.<key>.infrastructure_encryption_enabled` | `true` (enforced, validation rejects `false`) |

### Networking

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Default action | `storage_accounts.<key>.network_rules.default_action` | `"Allow"`, `"Deny"` (default: `"Deny"`) |
| Bypass | `storage_accounts.<key>.network_rules.bypass` | List of strings (default: `["AzureServices"]`) |
| IP rules | `storage_accounts.<key>.network_rules.ip_rules` | List of CIDR ranges |
| VNet subnet IDs | `storage_accounts.<key>.network_rules.virtual_network_subnet_ids` | List of subnet resource IDs |

### Blob Properties

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Versioning | `storage_accounts.<key>.blob_properties.versioning_enabled` | `true`, `false` (default: `true`) |
| Change feed | `storage_accounts.<key>.blob_properties.change_feed_enabled` | `true`, `false` (default: `true`) |
| Last access time tracking | `storage_accounts.<key>.blob_properties.last_access_time_enabled` | `true`, `false` (default: `false`) |
| Blob soft delete days | `storage_accounts.<key>.blob_properties.delete_retention_policy.days` | Number of days (default: `30`) |
| Container soft delete days | `storage_accounts.<key>.blob_properties.container_delete_retention_policy.days` | Number of days (default: `30`) |

### Encryption

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Key Vault key ID | `storage_accounts.<key>.customer_managed_key.key_vault_key_id` | Key Vault key resource ID |
| User-assigned identity ID | `storage_accounts.<key>.customer_managed_key.user_assigned_identity_id` | User-assigned identity resource ID |

### Identity

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Identity type | `storage_accounts.<key>.identity.type` | `"SystemAssigned"`, `"UserAssigned"`, `"SystemAssigned, UserAssigned"` (default: `"SystemAssigned"`) |
| Identity IDs | `storage_accounts.<key>.identity.identity_ids` | List of user-assigned identity resource IDs |

### Sub-Resources

#### Blob Containers

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Container name | `storage_accounts.<key>.containers.<name>.name` | Container name |
| Access type | `storage_accounts.<key>.containers.<name>.container_access_type` | `"private"`, `"blob"`, `"container"` (default: `"private"`) |

#### File Shares

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Share name | `storage_accounts.<key>.file_shares.<name>.name` | File share name |
| Quota (GB) | `storage_accounts.<key>.file_shares.<name>.quota` | Number (default: `50`) |

#### Queues

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Queue name | `storage_accounts.<key>.queues.<name>.name` | Queue name |

#### Tables

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Table name | `storage_accounts.<key>.tables.<name>.name` | Table name |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |
| Per-account tags | `storage_accounts.<key>.tags` | `map(string)`, merged with module-level tags |

## Enforced Policies

- **HTTPS only**: Validation rejects any storage account with `enable_https_traffic_only = false`. All traffic must use HTTPS.
- **TLS 1.2 minimum**: Validation rejects any storage account with `min_tls_version` set to anything other than `"TLS1_2"`.
- **Public blob access disabled**: Validation rejects any storage account with `allow_nested_items_to_be_public = true`. Anonymous access to blob data is not permitted.
- **Shared access key disabled**: Validation rejects any storage account with `shared_access_key_enabled = true`. Use Azure AD authentication instead.
- **Public network access disabled**: Validation rejects any storage account with `public_network_access_enabled = true`. Use private endpoints for connectivity.
- **Infrastructure encryption enabled**: Validation rejects any storage account with `infrastructure_encryption_enabled = false`. Double encryption at the infrastructure layer is required.
- **Geo-redundant replication**: Storage accounts default to `account_replication_type = "GRS"` for cross-region redundancy.
- **Blob versioning enabled**: Blob properties default to `versioning_enabled = true` and `change_feed_enabled = true`.
- **Soft delete enabled**: Both blob and container soft delete default to 30-day retention.
- **System-assigned identity**: All storage accounts default to a SystemAssigned managed identity.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Deletion protection**: OPA policy denies deletion or replacement of storage accounts in CI/CD pipelines.
