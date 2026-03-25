# az-nat-gateway

Creates and manages Azure NAT Gateways with public IP, prefix, and subnet associations.

## Usage

```hcl
module "nat" {
  source              = "../az-nat-gateway"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  nat_gateways = {
    main = {
      name              = "natgw-main"
      public_ip_ids     = [module.pip.public_ips["nat"].id]
      subnet_ids        = [module.vnet.subnets["hub-default"].id]
      zones             = ["1"]
      idle_timeout_in_minutes = 10
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
| SKU | `nat_gateways.<key>.sku_name` | `"Standard"` | `"Standard"` |

### Networking

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| Idle timeout | `nat_gateways.<key>.idle_timeout_in_minutes` | `4`--`120` | `4` |
| Public IP IDs | `nat_gateways.<key>.public_ip_ids` | List of PIP resource IDs | `[]` |
| Public IP prefix IDs | `nat_gateways.<key>.public_ip_prefix_ids` | List of prefix resource IDs | `[]` |
| Subnet IDs | `nat_gateways.<key>.subnet_ids` | List of subnet resource IDs | `[]` |

### Scaling

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Availability zones | `nat_gateways.<key>.zones` | `["1"]`, `["1","2","3"]`, etc. |

## Enforced Policies

- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **SKU validation**: Only `"Standard"` is accepted -- enforced at plan time.
- **Idle timeout validation**: Must be between 4 and 120 minutes -- enforced at plan time.
