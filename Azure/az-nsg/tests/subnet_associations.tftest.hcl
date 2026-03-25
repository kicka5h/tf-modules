mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  nsgs = {
    web = {
      name = "nsg-web"
      subnet_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/web-01",
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/web-02",
      ]
    }
    db = {
      name = "nsg-db"
      subnet_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/data",
      ]
    }
  }
}

run "creates_subnet_associations" {
  command = plan

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 3
    error_message = "Expected 3 subnet associations"
  }

  assert {
    condition     = azurerm_subnet_network_security_group_association.this["web-0"].subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/web-01"
    error_message = "Expected first web subnet association"
  }

  assert {
    condition     = azurerm_subnet_network_security_group_association.this["web-1"].subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/web-02"
    error_message = "Expected second web subnet association"
  }

  assert {
    condition     = azurerm_subnet_network_security_group_association.this["db-0"].subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-app/subnets/data"
    error_message = "Expected db subnet association"
  }
}
