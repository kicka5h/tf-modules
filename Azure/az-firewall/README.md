# az-firewall

Creates and manages Azure Firewalls with inline firewall policies, rule collection groups, and automatic IP/FQDN blocklist enforcement.

## Usage

```hcl
module "firewall" {
  source              = "../az-firewall"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  firewalls = {
    hub = {
      name     = "fw-hub"
      sku_tier = "Standard"
      ip_configuration = {
        name                 = "fw-ipconfig"
        subnet_id            = module.vnet.subnets["hub-AzureFirewallSubnet"].id
        public_ip_address_id = module.pip.public_ips["firewall"].id
      }
      policy = {
        rule_collection_groups = {
          app_rules = {
            name     = "app-rules"
            priority = 300
            application_rule_collections = {
              allow_web = {
                name     = "allow-web"
                priority = 100
                action   = "Allow"
                rules = {
                  allow_google = {
                    name              = "allow-google"
                    destination_fqdns = ["*.google.com"]
                    protocols = [{ type = "Https", port = 443 }]
                  }
                }
              }
            }
          }
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

### SKU/Tier

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| SKU name | `firewalls.<key>.sku_name` | `"AZFW_VNet"`, `"AZFW_Hub"` | `"AZFW_VNet"` |
| SKU tier | `firewalls.<key>.sku_tier` | `"Basic"`, `"Standard"`, `"Premium"` | `"Standard"` |

### Modes

| What | Variable Path | Valid Values | Default |
| --- | --- | --- | --- |
| Threat intel mode (firewall) | `firewalls.<key>.threat_intel_mode` | `"Alert"`, `"Deny"`, `"Off"` | `"Alert"` |
| Threat intel mode (policy) | `firewalls.<key>.policy.threat_intelligence_mode` | `"Alert"`, `"Deny"`, `"Off"` | `"Alert"` |

### Custom Rules

| What | Variable Path | Notes |
| --- | --- | --- |
| Rule collection groups | `firewalls.<key>.policy.rule_collection_groups` | Map of groups, each with `name`, `priority`, collections |
| Group priority | `firewalls.<key>.policy.rule_collection_groups.<name>.priority` | Must be `>= 300` |
| Application rule collections | `...rule_collection_groups.<name>.application_rule_collections` | Map with `name`, `priority`, `action`, `rules` |
| Network rule collections | `...rule_collection_groups.<name>.network_rule_collections` | Map with `name`, `priority`, `action`, `rules` |
| External policy | `firewalls.<key>.firewall_policy_id` | Set to use an external policy instead of inline |

### Networking

| What | Variable Path | Notes |
| --- | --- | --- |
| IP configuration | `firewalls.<key>.ip_configuration` | Required: `name`, `subnet_id`, `public_ip_address_id` |
| Management IP config | `firewalls.<key>.management_ip_configuration` | Optional, for forced tunneling |
| DNS proxy | `firewalls.<key>.dns.proxy_enabled` | `true`, `false` |
| DNS servers | `firewalls.<key>.dns.servers` | List of IP addresses |

### Scaling

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Availability zones | `firewalls.<key>.zones` | `["1"]`, `["1","2","3"]`, etc. |

### IP/CIDR Updates

The module automatically fetches and enforces IP blocklists. **No caller configuration is needed.**

| Source | URL |
| --- | --- |
| Spamhaus DROP | `https://www.spamhaus.org/drop/drop.txt` |
| Spamhaus EDROP | `https://www.spamhaus.org/drop/edrop.txt` |
| Custom org IP blocklist | `https://raw.githubusercontent.com/<org>/blocked-hosts/main/ip-blocklist.txt` |

To update the custom org IP blocklist, commit changes to `github.com/<org>/blocked-hosts/main/ip-blocklist.txt` (one CIDR per line, `#` for comments). Changes take effect on the next `terraform apply`.

### FQDN Updates

The module automatically fetches and enforces FQDN blocklists. **No caller configuration is needed.**

| Source | URL |
| --- | --- |
| Ultimate Hosts Blacklist | `https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/hosts/hosts0` |
| Custom org FQDN blocklist | `https://raw.githubusercontent.com/<org>/blocked-hosts/main/fqdn-blocklist.txt` |

To update the custom org FQDN blocklist, commit changes to `github.com/<org>/blocked-hosts/main/fqdn-blocklist.txt` (one domain per line, `#` for comments). Changes take effect on the next `terraform apply`.

| What | Variable | Notes |
| --- | --- | --- |
| Max FQDNs imported | `fqdn_blocklist_max` | Default: `1000`. Set to `0` to disable Ultimate Hosts import. |

## Reserved Priority Ranges

| Range | Owner | Purpose |
| --- | --- | --- |
| `200` | Module | Enforced blocklist rule collection group (`enforced-blocklists`) |
| `100`--`299` | Module | Reserved -- do not use for caller rule collection groups |
| `300`+ | Caller | Available for user-defined rule collection groups |

Caller rule collection group priorities **must** be `>= 300`.

## Enforced Policies

- **Blocklist rule collection group**: A rule collection group named `enforced-blocklists` at priority `200` is automatically created on every inline firewall policy. It contains:
  - Application rule collection denying HTTP/HTTPS to blocklisted FQDNs
  - Network rule collection denying TCP/UDP to blocklisted FQDNs on all ports
  - Network rule collection denying TCP/UDP/ICMP to/from blocklisted IP CIDRs
- **Inline policy creation**: When `firewall_policy_id` is not set, the module creates a firewall policy automatically.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
