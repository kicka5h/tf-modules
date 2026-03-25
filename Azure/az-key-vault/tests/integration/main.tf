resource "azurerm_resource_group" "test" {
  name     = "rg-kv-integration-test"
  location = "eastus2"
}

module "key_vault" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  key_vaults = {
    test = {
      name     = "kv-inttest-${substr(md5("integration"), 0, 8)}"
      sku_name = "premium"
    }
  }

  tags = { environment = "integration-test" }
}

output "vault_id" {
  value = module.key_vault.key_vaults["test"].id
}

output "vault_uri" {
  value = module.key_vault.key_vaults["test"].vault_uri
}
