# az-dns-zone

Creates and manages Azure public and private DNS zones, including virtual network links for private zones.

## Usage

```hcl
module "dns" {
  source              = "../az-dns-zone"
  resource_group_name = "rg-networking"

  dns_zones = {
    public_example = {
      name = "example.com"
      type = "public"
    }
    private_internal = {
      name = "internal.example.com"
      type = "private"
      vnet_links = {
        hub = {
          virtual_network_id   = module.vnet.vnets["hub"].id
          registration_enabled = true
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

### Tags

| What | Variable | Notes |
| --- | --- | --- |
| Custom tags | `tags` | `map(string)`, merged with default tags |

### DNS Zones

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Zone name | `dns_zones.<key>.name` | Any valid DNS zone name |
| Zone type | `dns_zones.<key>.type` | `"public"`, `"private"` |
| VNet links (private only) | `dns_zones.<key>.vnet_links.<link_key>.virtual_network_id` | Resource ID of the VNet |
| Auto-registration | `dns_zones.<key>.vnet_links.<link_key>.registration_enabled` | `true`, `false` (default: `false`) |

## Enforced Policies

- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Type validation**: Zone type must be `"public"` or `"private"` -- enforced at plan time.
