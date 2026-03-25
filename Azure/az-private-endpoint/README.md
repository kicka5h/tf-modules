# az-private-endpoint

Creates and manages Azure Private Endpoints with mandatory DNS zone groups and optional static IP configurations.

## Usage

```hcl
module "pe" {
  source              = "../az-private-endpoint"
  resource_group_name = "rg-networking"
  location            = "eastus2"

  private_endpoints = {
    storage = {
      name      = "pe-storage"
      subnet_id = module.vnet.subnets["hub-endpoints"].id
      private_service_connection = {
        name                           = "psc-storage"
        private_connection_resource_id = azurerm_storage_account.this.id
        subresource_names              = ["blob"]
      }
      private_dns_zone_group = {
        name                 = "default"
        private_dns_zone_ids = [module.dns.private_zones["blob"].id]
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

| What | Variable Path | Notes |
| --- | --- | --- |
| Subnet | `private_endpoints.<key>.subnet_id` | Subnet resource ID where the PE is created |
| Target resource | `private_endpoints.<key>.private_service_connection.private_connection_resource_id` | Resource ID of the service to connect to |
| Subresource | `private_endpoints.<key>.private_service_connection.subresource_names` | e.g. `["blob"]`, `["sqlServer"]`, `["vault"]` |
| Manual connection | `private_endpoints.<key>.private_service_connection.is_manual_connection` | `true`, `false` (default: `false`) |
| Request message | `private_endpoints.<key>.private_service_connection.request_message` | Required when `is_manual_connection = true` |
| DNS zone group name | `private_endpoints.<key>.private_dns_zone_group.name` | Typically `"default"` |
| DNS zone IDs | `private_endpoints.<key>.private_dns_zone_group.private_dns_zone_ids` | List of private DNS zone resource IDs |

### Static IP Configuration

```hcl
ip_configuration = [
  {
    name               = "ip-config"
    private_ip_address  = "10.0.1.10"
    subresource_name   = "blob"
    member_name        = "blob"
  }
]
```

## Enforced Policies

- **Mandatory DNS zone group**: Every private endpoint **must** include a `private_dns_zone_group`. Omitting it is rejected at plan time. This prevents the common misconfiguration where private endpoints are created without DNS integration, breaking name resolution.
- **Default tags**: `Terraform = "true"` is always applied and merged with caller-provided tags.
