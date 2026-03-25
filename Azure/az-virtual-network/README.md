# az-virtual-network

Creates and manages Azure Virtual Networks with subnets, service endpoints, delegations, DDoS protection, and encryption.

## Usage

```hcl
module "vnet" {
  source              = "../az-virtual-network"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  vnets = {
    hub = {
      name          = "vnet-hub"
      address_space = ["10.0.0.0/16"]
      dns_servers   = ["10.0.0.4", "10.0.0.5"]
      subnets = {
        default = {
          address_prefixes = ["10.0.1.0/24"]
        }
        AzureFirewallSubnet = {
          address_prefixes  = ["10.0.2.0/24"]
          service_endpoints = ["Microsoft.Storage"]
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

### Networking

| What | Variable Path | Valid Values |
| --- | --- | --- |
| Address space | `vnets.<key>.address_space` | List of CIDR blocks |
| DNS servers | `vnets.<key>.dns_servers` | List of IP addresses (default: Azure-provided) |
| Flow timeout | `vnets.<key>.flow_timeout_in_minutes` | Number or `null` |
| Subnet CIDRs | `vnets.<key>.subnets.<name>.address_prefixes` | List of CIDR blocks |
| Service endpoints | `vnets.<key>.subnets.<name>.service_endpoints` | e.g. `["Microsoft.Storage", "Microsoft.Sql"]` |
| Private endpoint policies | `vnets.<key>.subnets.<name>.private_endpoint_network_policies` | `"Disabled"` (default), `"Enabled"` |
| Private link service policies | `vnets.<key>.subnets.<name>.private_link_service_network_policies_enabled` | `true`, `false` (default: `false`) |

### Subnet Delegation

```hcl
subnets = {
  appservice = {
    address_prefixes = ["10.0.3.0/24"]
    delegation = {
      name = "appservice-delegation"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}
```

### Encryption/Security

| What | Variable Path | Valid Values |
| --- | --- | --- |
| VNet encryption | `vnets.<key>.encryption.enforcement` | `"DropUnencrypted"`, `"AllowUnencrypted"` |
| DDoS protection plan | `vnets.<key>.ddos_protection_plan.id` | Resource ID of the DDoS plan |
| DDoS enable | `vnets.<key>.ddos_protection_plan.enable` | `true`, `false` |

## Enforced Policies

- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
