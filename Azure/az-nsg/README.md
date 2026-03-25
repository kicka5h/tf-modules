# az-nsg

Creates and manages Azure Network Security Groups with caller-defined rules, automatic IP blocklist enforcement, and subnet associations.

## Usage

```hcl
module "nsg" {
  source              = "../az-nsg"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  nsgs = {
    web = {
      name = "nsg-web"
      rules = {
        allow_https = {
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
      subnet_ids = [module.vnet.subnets["hub-web"].id]
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

### Custom Rules

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Priority | `nsgs.<key>.rules.<name>.priority` | `200`--`4096` (100-199 reserved) |
| Direction | `nsgs.<key>.rules.<name>.direction` | `"Inbound"`, `"Outbound"` |
| Access | `nsgs.<key>.rules.<name>.access` | `"Allow"`, `"Deny"` |
| Protocol | `nsgs.<key>.rules.<name>.protocol` | `"Tcp"`, `"Udp"`, `"Icmp"`, `"*"` |
| Source port | `nsgs.<key>.rules.<name>.source_port_range` | Port or range (default: `"*"`) |
| Source ports (list) | `nsgs.<key>.rules.<name>.source_port_ranges` | List of ports/ranges |
| Dest port | `nsgs.<key>.rules.<name>.destination_port_range` | Port or range |
| Dest ports (list) | `nsgs.<key>.rules.<name>.destination_port_ranges` | List of ports/ranges |
| Source CIDR | `nsgs.<key>.rules.<name>.source_address_prefix` | Single CIDR or `"*"` |
| Source CIDRs (list) | `nsgs.<key>.rules.<name>.source_address_prefixes` | List of CIDRs |
| Dest CIDR | `nsgs.<key>.rules.<name>.destination_address_prefix` | Single CIDR or `"*"` |
| Dest CIDRs (list) | `nsgs.<key>.rules.<name>.destination_address_prefixes` | List of CIDRs |
| Source ASGs | `nsgs.<key>.rules.<name>.source_application_security_group_ids` | List of ASG IDs |
| Dest ASGs | `nsgs.<key>.rules.<name>.destination_application_security_group_ids` | List of ASG IDs |
| Subnet associations | `nsgs.<key>.subnet_ids` | List of subnet resource IDs |

### IP/CIDR Updates

The module automatically fetches and enforces IP blocklists. **No caller configuration is needed.**

| Source | URL |
| --- | --- |
| Spamhaus DROP | `https://www.spamhaus.org/drop/drop.txt` |
| Spamhaus EDROP | `https://www.spamhaus.org/drop/edrop.txt` |
| Custom org blocklist | `https://raw.githubusercontent.com/<org>/blocked-hosts/main/ip-blocklist.txt` |

To update the custom org blocklist, commit changes to `github.com/<org>/blocked-hosts/main/ip-blocklist.txt` (one CIDR per line, `#` for comments). Changes take effect on the next `terraform apply`.

## Reserved Priority Ranges

| Range | Owner | Purpose |
| --- | --- | --- |
| `100` | Module | Spamhaus DROP+EDROP and org IP blocklist deny rules (inbound + outbound) |
| `200`--`4096` | Caller | Available for user-defined rules |

Priority `100` is used for both the inbound and outbound blocklist deny rules. Caller rules **must** use priority `>= 200`.

## Enforced Policies

- **IP blocklist deny rules**: Two rules (inbound + outbound) at priority `100` are automatically created on every NSG. They deny all traffic to/from Spamhaus DROP+EDROP CIDRs and the custom org IP blocklist.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Priority validation**: Caller rules with priority `< 200` are rejected at plan time.
