# az-vmss

Creates and manages Azure Virtual Machine Scale Sets (both Linux and Windows) with enforced security defaults, rolling upgrade policies, and zone balancing.

## Usage

```hcl
module "vmss" {
  source              = "../az-vmss"
  resource_group_name = "rg-compute"
  location            = "eastus2"

  scale_sets = {
    web = {
      name           = "vmss-web-linux"
      os_type        = "linux"
      sku            = "Standard_D2s_v5"
      instances      = 3
      zones          = ["1", "2", "3"]
      admin_username = "azureadmin"
      admin_ssh_key = {
        public_key = file("~/.ssh/id_rsa.pub")
      }
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
      network_interface = {
        name      = "nic-web"
        subnet_id = module.vnet.subnets["hub-web"].id
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Configuration Reference

### Scaling

| What | Variable Path | Notes |
| --- | --- | --- |
| Instance count | `scale_sets.<key>.instances` | Default: `2` |
| VM size | `scale_sets.<key>.sku` | e.g. `"Standard_D2s_v5"` |

### Zones

| What | Variable Path | Notes |
| --- | --- | --- |
| Availability zones | `scale_sets.<key>.zones` | List of zone strings, e.g. `["1", "2", "3"]` |
| Zone balancing | `scale_sets.<key>.zone_balance` | Default: `true` (enforced) |

### Upgrade Policy

| What | Variable Path | Notes |
| --- | --- | --- |
| Upgrade mode | `scale_sets.<key>.upgrade_mode` | Default: `"Rolling"` (enforced) |
| Max batch % | `scale_sets.<key>.rolling_upgrade_policy.max_batch_instance_percent` | Default: `20` |
| Max unhealthy % | `scale_sets.<key>.rolling_upgrade_policy.max_unhealthy_instance_percent` | Default: `20` |
| Max unhealthy upgraded % | `scale_sets.<key>.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent` | Default: `20` |
| Pause between batches | `scale_sets.<key>.rolling_upgrade_policy.pause_time_between_batches` | Default: `"PT2S"` |
| Auto OS upgrade | `scale_sets.<key>.automatic_os_upgrade_policy.enable_automatic_os_upgrade` | Default: `true` when block is set |

### Health Probes

| What | Variable Path | Notes |
| --- | --- | --- |
| Health probe ID | `scale_sets.<key>.health_probe_id` | Load balancer health probe resource ID |
| Auto instance repair | `scale_sets.<key>.automatic_instance_repair.enabled` | Default: `true` when block is set |
| Repair grace period | `scale_sets.<key>.automatic_instance_repair.grace_period` | Default: `"PT30M"` |

### Identity

| What | Variable Path | Notes |
| --- | --- | --- |
| Identity type | `scale_sets.<key>.identity.type` | Default: `"SystemAssigned"` (enforced) |
| User-assigned IDs | `scale_sets.<key>.identity.identity_ids` | Required when type includes `UserAssigned` |

### Trusted Launch

| What | Variable Path | Notes |
| --- | --- | --- |
| Secure boot | `scale_sets.<key>.secure_boot_enabled` | Default: `true` (enforced) |
| vTPM | `scale_sets.<key>.vtpm_enabled` | Default: `true` (enforced) |
| Encryption at host | `scale_sets.<key>.encryption_at_host_enabled` | Default: `false` |

### Data Disks

| What | Variable Path | Notes |
| --- | --- | --- |
| Storage type | `scale_sets.<key>.data_disks.<name>.storage_account_type` | Default: `"Premium_LRS"` |
| Size | `scale_sets.<key>.data_disks.<name>.disk_size_gb` | Required |
| Caching | `scale_sets.<key>.data_disks.<name>.caching` | Default: `"ReadOnly"` |
| LUN | `scale_sets.<key>.data_disks.<name>.lun` | Required, must be unique per VMSS |
| Encryption set | `scale_sets.<key>.data_disks.<name>.disk_encryption_set_id` | Optional |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Module-level tags | `tags` | `map(string)`, merged with default tags |
| Per-VMSS tags | `scale_sets.<key>.tags` | `map(string)`, merged with module tags |

## Enforced Policies

- **Trusted launch**: `secure_boot_enabled` and `vtpm_enabled` default to `true` on all scale sets.
- **System-assigned identity**: Every VMSS gets a `SystemAssigned` managed identity by default.
- **Boot diagnostics**: Enabled on all scale sets (uses managed storage by default).
- **Zone balancing**: `zone_balance` defaults to `true` to distribute instances evenly across zones.
- **Rolling upgrade policy**: `upgrade_mode` defaults to `"Rolling"` with conservative batch and health thresholds.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Deletion protection**: OPA policy denies deletion or replacement of VMSS resources at plan time.
