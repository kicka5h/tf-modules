# Full-Stack Networking Example

This example demonstrates how the IPAM module feeds IP addresses into every networking module automatically. The caller never writes a CIDR — they define the shape of their network (VNet names, subnet names, sizes) and IPAM calculates all addresses from a single root block.

## What the caller defines (in .tfvars)

```hcl
ipam_allocation = {
  cidr_newbits = 8      # /16 for this environment
  cidr_index   = 0      # first /16 from the root /8
  vnets = {
    hub = {
      cidr_newbits = 4   # /20 for this VNet
      cidr_index   = 0
      subnets = {
        GatewaySubnet = { cidr_newbits = 4, cidr_index = 0 }  # /24
        app           = { cidr_newbits = 2, cidr_index = 0 }  # /22
      }
    }
  }
}

nsg_rules = {
  app = {
    allow_https = { priority = 200, direction = "Inbound", ... }
  }
}
```

## What IPAM calculates

```
10.0.0.0/8 (root)
  └── 10.0.0.0/16 (dev, index 0)
        ├── 10.0.0.0/20 (hub VNet)
        │     ├── 10.0.0.0/24 (GatewaySubnet)
        │     └── 10.0.1.0/24 (AzureFirewallSubnet)
        └── 10.0.16.0/20 (spoke VNet)
              ├── 10.0.16.0/22 (app)
              ├── 10.0.20.0/24 (data)
              └── 10.0.24.0/22 (aks)
```

## What gets created

The `shared/main.tf` wires IPAM outputs into modules:

1. **IPAM** calculates CIDRs from the allocation plan
2. **az-virtual-network** creates VNets + subnets using IPAM addresses
3. **az-nsg** creates NSGs and auto-associates with subnets by name
4. **az-route-table** creates route tables and auto-associates with subnets by name

The caller just defines NSG rules and route tables referencing subnet names — the modules resolve everything to actual IDs and CIDRs internally.

## Adding a new environment

1. Create `environments/<env>/<env>.tfvars`
2. Set a new `cidr_index` (e.g., `cidr_index = 4` for a fifth /16)
3. Copy the VNet/subnet shape from an existing environment (or customize)
4. The pipeline deploys it — no CIDR conflicts possible

## Adding a new subnet

1. Add an entry to the `vnets.<vnet>.subnets` map in the tfvars
2. Pick the next available `cidr_index` within that VNet
3. Optionally add NSG rules for the new subnet name
4. The VNet module picks up the new subnet automatically
