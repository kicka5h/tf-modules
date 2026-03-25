resource "azurerm_resource_group" "test" {
  name     = "rg-integration-test"
  location = "eastus2"
}

module "vnet" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  vnets = {
    test = {
      name          = "vnet-integration-test"
      address_space = ["10.0.0.0/16"]
      subnets = {
        default = {
          address_prefixes = ["10.0.1.0/24"]
        }
        app = {
          address_prefixes  = ["10.0.2.0/24"]
          service_endpoints = ["Microsoft.Storage"]
        }
      }
    }
  }

  tags = {
    environment = "integration-test"
  }
}

output "vnet_id" {
  value = module.vnet.vnets["test"].id
}

output "subnet_ids" {
  value = { for k, v in module.vnet.subnets : k => v.id }
}
