# az-virtual-machine

Creates and manages Azure Virtual Machines (Linux and Windows) with automatic NIC creation, managed data disks, and security-by-default configuration.

## Usage

```hcl
module "virtual_machines" {
  source              = "../az-virtual-machine"
  resource_group_name = "rg-compute"
  location            = "eastus2"

  virtual_machines = {
    web = {
      name           = "vm-web-01"
      os_type        = "linux"
      size           = "Standard_D2s_v3"
      zone           = "1"
      admin_username = "azureadmin"
      admin_ssh_key = {
        public_key = file("~/.ssh/id_rsa.pub")
      }
      subnet_id = module.vnet.subnets["main-web"].id
      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }
      data_disks = {
        app = {
          name         = "vm-web-01-app"
          disk_size_gb = 128
          lun          = 0
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

### OS Type

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Operating system | `virtual_machines.<key>.os_type` | `"linux"`, `"windows"` |

Linux VMs use `azurerm_linux_virtual_machine`. Windows VMs use `azurerm_windows_virtual_machine`. The module automatically routes each VM to the correct resource type.

### VM Size and Availability

| What | Variable Path | Notes |
| --- | --- | --- |
| VM size | `virtual_machines.<key>.size` | e.g., `"Standard_D2s_v3"`, `"Standard_D4s_v3"` |
| Availability zone | `virtual_machines.<key>.zone` | `"1"`, `"2"`, `"3"`, or `null` (default) |

### Authentication

| What | Variable Path | Notes |
| --- | --- | --- |
| Admin username | `virtual_machines.<key>.admin_username` | Required for all VMs |
| Admin password | `virtual_machines.<key>.admin_password` | Required for Windows, optional for Linux (sensitive) |
| SSH public key | `virtual_machines.<key>.admin_ssh_key.public_key` | Recommended for Linux VMs |

When `admin_ssh_key` is provided on a Linux VM, password authentication is automatically disabled.

### Networking

| What | Variable Path | Notes |
| --- | --- | --- |
| Subnet | `virtual_machines.<key>.subnet_id` | Required, subnet resource ID |
| Private IP | `virtual_machines.<key>.private_ip_address` | Static IP, or `null` for dynamic (default) |
| IP allocation | `virtual_machines.<key>.private_ip_address_allocation` | `"Dynamic"` (default) or `"Static"` |
| Public IP | `virtual_machines.<key>.public_ip_address_id` | `null` by default (no public IP) |

One NIC is automatically created per VM. No separate NIC variable is needed.

### OS Disk

| What | Variable Path | Default |
| --- | --- | --- |
| Caching | `virtual_machines.<key>.os_disk.caching` | `"ReadWrite"` |
| Storage type | `virtual_machines.<key>.os_disk.storage_account_type` | `"Premium_LRS"` |
| Disk size | `virtual_machines.<key>.os_disk.disk_size_gb` | Provider default |
| Encryption set | `virtual_machines.<key>.os_disk.disk_encryption_set_id` | `null` |

### Data Disks

| What | Variable Path | Default |
| --- | --- | --- |
| Disk name | `virtual_machines.<key>.data_disks.<disk_key>.name` | Required |
| Size (GB) | `virtual_machines.<key>.data_disks.<disk_key>.disk_size_gb` | Required |
| LUN | `virtual_machines.<key>.data_disks.<disk_key>.lun` | Required |
| Storage type | `virtual_machines.<key>.data_disks.<disk_key>.storage_account_type` | `"Premium_LRS"` |
| Caching | `virtual_machines.<key>.data_disks.<disk_key>.caching` | `"ReadOnly"` |
| Create option | `virtual_machines.<key>.data_disks.<disk_key>.create_option` | `"Empty"` |
| Encryption set | `virtual_machines.<key>.data_disks.<disk_key>.disk_encryption_set_id` | `null` |

Data disks are automatically attached to their parent VM at the specified LUN.

### Source Image

| What | Variable Path | Notes |
| --- | --- | --- |
| Publisher | `virtual_machines.<key>.source_image_reference.publisher` | e.g., `"Canonical"`, `"MicrosoftWindowsServer"` |
| Offer | `virtual_machines.<key>.source_image_reference.offer` | e.g., `"0001-com-ubuntu-server-jammy"`, `"WindowsServer"` |
| SKU | `virtual_machines.<key>.source_image_reference.sku` | e.g., `"22_04-lts-gen2"`, `"2022-datacenter-g2"` |
| Version | `virtual_machines.<key>.source_image_reference.version` | e.g., `"latest"` |

### Identity

| What | Variable Path | Default |
| --- | --- | --- |
| Identity type | `virtual_machines.<key>.identity.type` | `"SystemAssigned"` |
| User-assigned IDs | `virtual_machines.<key>.identity.identity_ids` | `[]` |

### Trusted Launch

| What | Variable Path | Default |
| --- | --- | --- |
| Secure boot | `virtual_machines.<key>.secure_boot_enabled` | `true` |
| vTPM | `virtual_machines.<key>.vtpm_enabled` | `true` |
| Encryption at host | `virtual_machines.<key>.encryption_at_host_enabled` | `false` |

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Module tags | `tags` | `map(string)`, merged with default tags, applied to all resources |
| Per-VM tags | `virtual_machines.<key>.tags` | `map(string)`, merged with module tags |

## Enforced Policies

- **Trusted launch**: Secure boot and vTPM are enabled by default on all VMs. Use Gen2 images (`-gen2` / `-g2` SKUs) for compatibility.
- **Managed identity**: System-assigned managed identity is configured by default, enabling passwordless access to Azure services.
- **Boot diagnostics**: Enabled by default on all VMs. Omit `storage_account_uri` to use managed storage.
- **No public IP**: Public IP is `null` by default. VMs are private unless explicitly configured otherwise.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Deletion protection**: OPA policy denies deletion or replacement of VM resources. Request an exception to remove a VM.
