resource_group_name = "rg-network"
location            = "eastus2"

# Note: Priorities 100-199 are reserved for module-enforced blocklist rules
# (Spamhaus DROP+EDROP and custom org IP blocklist).
# User-defined rules must use priority >= 200.

nsgs = {
  web_tier = {
    name = "nsg-web-tier"
    rules = {
      allow_https_inbound = {
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        description                = "Allow HTTPS from anywhere"
      }
      allow_http_inbound = {
        priority                   = 210
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        description                = "Allow HTTP from anywhere"
      }
      allow_ssh_from_bastion = {
        priority                   = 220
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "10.0.1.0/24"
        destination_address_prefix = "*"
        description                = "Allow SSH from bastion subnet only"
      }
      deny_all_inbound = {
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        description                = "Deny all other inbound traffic"
      }
    }
    subnet_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/web-01",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/web-02",
    ]
  }

  db_tier = {
    name = "nsg-db-tier"
    rules = {
      allow_sql_from_web = {
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.0.10.0/24"
        destination_address_prefix = "*"
        description                = "Allow SQL Server from web tier"
      }
      allow_sql_from_app = {
        priority                   = 210
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["1433", "5432"]
        source_address_prefix      = "10.0.20.0/24"
        destination_address_prefix = "*"
        description                = "Allow SQL and PostgreSQL from app tier"
      }
      deny_all_inbound = {
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        description                = "Deny all other inbound traffic"
      }
    }
    subnet_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/data",
    ]
  }

  bastion = {
    name = "nsg-bastion"
    rules = {
      allow_ssh_inbound = {
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = ["203.0.113.0/24", "198.51.100.0/24"]
        destination_address_prefix = "*"
        description                = "Allow SSH from trusted CIDRs"
      }
    }
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
