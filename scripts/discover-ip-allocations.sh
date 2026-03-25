#!/usr/bin/env bash
# Discovers all existing IP allocations across an Azure tenant.
#
# Uses Azure Resource Graph to query all VNets, subnets, public IPs,
# and private endpoints across all subscriptions in a single call.
#
# Prerequisites:
#   - Azure CLI installed and logged in (az login)
#   - Reader access across target subscriptions
#
# Usage:
#   ./scripts/discover-ip-allocations.sh                          # output to stdout
#   ./scripts/discover-ip-allocations.sh > reserved_cidrs.json    # save to file
#   ./scripts/discover-ip-allocations.sh --tfvars > reserved.auto.tfvars  # tfvars format

set -euo pipefail

FORMAT="json"
if [ "${1:-}" = "--tfvars" ]; then
  FORMAT="tfvars"
fi

# Check prerequisites
if ! command -v az &> /dev/null; then
  echo "ERROR: Azure CLI (az) is not installed." >&2
  exit 1
fi

if ! az account show &> /dev/null 2>&1; then
  echo "ERROR: Not logged in to Azure CLI. Run 'az login' first." >&2
  exit 1
fi

echo "Discovering IP allocations across tenant..." >&2

# Query all VNets and their address spaces
VNETS=$(az graph query -q "
  Resources
  | where type == 'microsoft.network/virtualnetworks'
  | project
      name,
      resourceGroup,
      subscriptionId,
      location,
      addressPrefixes = properties.addressSpace.addressPrefixes
" --first 1000 -o json 2>/dev/null)

# Query all subnets and their address prefixes
SUBNETS=$(az graph query -q "
  Resources
  | where type == 'microsoft.network/virtualnetworks'
  | mv-expand subnet = properties.subnets
  | project
      vnetName = name,
      subnetName = subnet.name,
      resourceGroup,
      subscriptionId,
      addressPrefix = subnet.properties.addressPrefix,
      addressPrefixes = subnet.properties.addressPrefixes
" --first 5000 -o json 2>/dev/null)

# Query all public IPs
PUBLIC_IPS=$(az graph query -q "
  Resources
  | where type == 'microsoft.network/publicipaddresses'
  | project
      name,
      resourceGroup,
      subscriptionId,
      ipAddress = properties.ipAddress,
      publicIPAllocationMethod = properties.publicIPAllocationMethod,
      sku = sku.name
" --first 1000 -o json 2>/dev/null)

# Build combined output
VNET_COUNT=$(echo "$VNETS" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null || echo "0")
SUBNET_COUNT=$(echo "$SUBNETS" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null || echo "0")
PIP_COUNT=$(echo "$PUBLIC_IPS" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null || echo "0")

echo "Found: $VNET_COUNT VNets, $SUBNET_COUNT subnets, $PIP_COUNT public IPs" >&2

if [ "$FORMAT" = "tfvars" ]; then
  # Output as tfvars format for the IPAM module
  python3 << 'PYTHON'
import json, sys

vnets_raw = json.loads("""VNETS_PLACEHOLDER""")
subnets_raw = json.loads("""SUBNETS_PLACEHOLDER""")
pips_raw = json.loads("""PIPS_PLACEHOLDER""")

vnets = vnets_raw.get("data", [])
subnets = subnets_raw.get("data", [])
pips = pips_raw.get("data", [])

# Collect all unique CIDRs
reserved = set()
for v in vnets:
    for prefix in (v.get("addressPrefixes") or []):
        reserved.add(prefix)
for s in subnets:
    if s.get("addressPrefix"):
        reserved.add(s["addressPrefix"])
    for prefix in (s.get("addressPrefixes") or []):
        reserved.add(prefix)

print("reserved_cidrs = [")
for cidr in sorted(reserved):
    print(f'  "{cidr}",')
print("]")
print()
print("existing_vnets = {")
for v in vnets:
    key = f'{v.get("subscriptionId","")[:8]}-{v.get("name","")}'
    prefixes = v.get("addressPrefixes") or []
    prefixes_str = ", ".join(f'"{p}"' for p in prefixes)
    print(f'  "{key}" = {{')
    print(f'    name              = "{v.get("name","")}"')
    print(f'    resource_group    = "{v.get("resourceGroup","")}"')
    print(f'    subscription_id   = "{v.get("subscriptionId","")}"')
    print(f'    location          = "{v.get("location","")}"')
    print(f'    address_prefixes  = [{prefixes_str}]')
    print(f'  }}')
print("}")
PYTHON
else
  # Output as JSON
  python3 << PYTHON
import json

vnets_raw = json.loads('''$(echo "$VNETS" | sed "s/'/\\\\'/g")''')
subnets_raw = json.loads('''$(echo "$SUBNETS" | sed "s/'/\\\\'/g")''')
pips_raw = json.loads('''$(echo "$PUBLIC_IPS" | sed "s/'/\\\\'/g")''')

vnets = vnets_raw.get("data", [])
subnets = subnets_raw.get("data", [])
pips = pips_raw.get("data", [])

# Collect all unique CIDRs
reserved = set()
for v in vnets:
    for prefix in (v.get("addressPrefixes") or []):
        reserved.add(prefix)
for s in subnets:
    if s.get("addressPrefix"):
        reserved.add(s["addressPrefix"])
    for prefix in (s.get("addressPrefixes") or []):
        reserved.add(prefix)

output = {
    "reserved_cidrs": sorted(list(reserved)),
    "vnets": [
        {
            "name": v.get("name"),
            "resource_group": v.get("resourceGroup"),
            "subscription_id": v.get("subscriptionId"),
            "location": v.get("location"),
            "address_prefixes": v.get("addressPrefixes", []),
        }
        for v in vnets
    ],
    "subnets": [
        {
            "vnet_name": s.get("vnetName"),
            "subnet_name": s.get("subnetName"),
            "resource_group": s.get("resourceGroup"),
            "subscription_id": s.get("subscriptionId"),
            "address_prefix": s.get("addressPrefix"),
        }
        for s in subnets
    ],
    "public_ips": [
        {
            "name": p.get("name"),
            "resource_group": p.get("resourceGroup"),
            "subscription_id": p.get("subscriptionId"),
            "ip_address": p.get("ipAddress"),
            "allocation_method": p.get("publicIPAllocationMethod"),
            "sku": p.get("sku"),
        }
        for p in pips
    ],
    "summary": {
        "total_vnets": len(vnets),
        "total_subnets": len(subnets),
        "total_public_ips": len(pips),
        "total_reserved_cidrs": len(reserved),
    },
}

print(json.dumps(output, indent=2))
PYTHON
fi
