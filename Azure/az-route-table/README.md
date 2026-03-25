# az-route-table

Creates and manages Azure Route Tables with user-defined routes and subnet associations.

## Usage

```hcl
module "routes" {
  source              = "../az-route-table"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  route_tables = {
    spoke = {
      name = "rt-spoke"
      routes = {
        to_firewall = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.2.4"
        }
      }
      subnet_ids = [module.vnet.subnets["hub-default"].id]
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
| BGP propagation | `route_tables.<key>.bgp_route_propagation_enabled` | `true` (default), `false` |
| Route destination | `route_tables.<key>.routes.<name>.address_prefix` | CIDR block |
| Next hop type | `route_tables.<key>.routes.<name>.next_hop_type` | `"VirtualNetworkGateway"`, `"VnetLocal"`, `"Internet"`, `"VirtualAppliance"`, `"None"` |
| Next hop IP | `route_tables.<key>.routes.<name>.next_hop_in_ip_address` | IP address (required when `next_hop_type = "VirtualAppliance"`) |
| Subnet associations | `route_tables.<key>.subnet_ids` | List of subnet resource IDs |

## Enforced Policies

- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
- **Next hop type validation**: Only the five documented values are accepted -- enforced at plan time.
- **VirtualAppliance next hop IP**: `next_hop_in_ip_address` is only set when `next_hop_type` is `"VirtualAppliance"`; it is forced to `null` for all other types.
