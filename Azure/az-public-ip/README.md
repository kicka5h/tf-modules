# az-public-ip

Creates and manages Azure Public IP addresses and Public IP Prefixes.

## Usage

```hcl
module "pip" {
  source              = "../az-public-ip"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  public_ips = {
    firewall = {
      name  = "pip-firewall"
      zones = ["1", "2", "3"]
    }
    gateway = {
      name              = "pip-gateway"
      domain_name_label = "myapp-gw"
    }
  }

  public_ip_prefixes = {
    nat = {
      name          = "pip-prefix-nat"
      prefix_length = 30
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Configuration Reference

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |

### SKU/Tier

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| PIP SKU | `public_ips.<key>.sku` | `"Standard"`, `"Basic"` | `"Standard"` |
| PIP SKU tier | `public_ips.<key>.sku_tier` | `"Regional"`, `"Global"` | `"Regional"` |
| Prefix SKU | `public_ip_prefixes.<key>.sku` | `"Standard"` | `"Standard"` |

### Networking

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| Allocation method | `public_ips.<key>.allocation_method` | `"Static"`, `"Dynamic"` | `"Static"` |
| IP version | `public_ips.<key>.ip_version` | `"IPv4"`, `"IPv6"` | `"IPv4"` |
| Idle timeout | `public_ips.<key>.idle_timeout_in_minutes` | `4`--`30` | `4` |
| Domain name label | `public_ips.<key>.domain_name_label` | String or `null` | `null` |
| Reverse FQDN | `public_ips.<key>.reverse_fqdn` | String or `null` | `null` |
| IP tags | `public_ips.<key>.ip_tags` | `map(string)` | `{}` |
| Public IP prefix ID | `public_ips.<key>.public_ip_prefix_id` | Resource ID or `null` | `null` |
| Prefix length | `public_ip_prefixes.<key>.prefix_length` | `28`--`31` (IPv4) | Required |
| Prefix IP version | `public_ip_prefixes.<key>.ip_version` | `"IPv4"`, `"IPv6"` | `"IPv4"` |

### Scaling

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Availability zones (PIP) | `public_ips.<key>.zones` | `["1"]`, `["1","2","3"]`, etc. |
| Availability zones (Prefix) | `public_ip_prefixes.<key>.zones` | `["1"]`, `["1","2","3"]`, etc. |

## Enforced Policies

- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
