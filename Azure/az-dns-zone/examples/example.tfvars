resource_group_name = "rg-dns-example"

dns_zones = {
  # Public zones
  contoso_public = {
    name = "contoso.com"
    type = "public"
  }
  api_public = {
    name = "api.contoso.com"
    type = "public"
  }
  marketing_public = {
    name = "marketing.contoso.com"
    type = "public"
  }

  # Private zones
  internal = {
    name = "internal.contoso.com"
    type = "private"
    vnet_links = {
      hub = {
        virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub"
        registration_enabled = true
      }
      spoke1 = {
        virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-spoke1"
        registration_enabled = false
      }
    }
  }
  database = {
    name = "db.contoso.com"
    type = "private"
    vnet_links = {
      hub = {
        virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-hub"
      }
    }
  }
  kubernetes = {
    name = "k8s.contoso.com"
    type = "private"
  }
}

tags = {
  environment = "production"
  managed_by  = "terraform"
}
