resource "azurerm_resource_group" "test" {
  name     = "rg-storage-integration-test"
  location = "eastus2"
}

module "storage" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  storage_accounts = {
    test = {
      name                     = "stinttest${substr(md5("integration"), 0, 8)}"
      account_tier             = "Standard"
      account_replication_type = "GRS"
      containers = {
        data = {
          name = "data"
        }
        logs = {
          name = "logs"
        }
      }
      file_shares = {
        share1 = {
          name  = "share1"
          quota = 10
        }
      }
    }
  }

  tags = { environment = "integration-test" }
}

output "storage_account_id" {
  value = module.storage.storage_accounts["test"].id
}

output "container_count" {
  value = length(module.storage.containers)
}
