resource "azurerm_resource_group" "test" {
  name     = "rg-nsg-integration-test"
  location = "eastus2"
}

module "nsg" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  nsgs = {
    web = {
      name = "nsg-web-test"
      rules = {
        allow_https = {
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          description                = "Allow HTTPS"
        }
        deny_all = {
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          description                = "Deny all inbound"
        }
      }
    }
  }

  tags = { environment = "integration-test" }
}

output "nsg_id" {
  value = module.nsg.nsgs["web"].id
}

output "rule_count" {
  value = length(module.nsg.rules)
}
