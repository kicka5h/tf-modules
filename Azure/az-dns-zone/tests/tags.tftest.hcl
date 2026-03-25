mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"

  dns_zones = {
    public_one = {
      name = "contoso.com"
      type = "public"
    }
    private_one = {
      name = "internal.contoso.com"
      type = "private"
    }
  }
}

run "default_terraform_tag_is_applied" {
  command = plan

  assert {
    condition     = azurerm_dns_zone.public["public_one"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag on public zone"
  }

  assert {
    condition     = azurerm_private_dns_zone.private["private_one"].tags["Terraform"] == "true"
    error_message = "Expected default Terraform tag on private zone"
  }
}

run "custom_tags_are_merged_with_defaults" {
  command = plan

  variables {
    tags = {
      environment = "test"
      team        = "platform"
    }
  }

  assert {
    condition     = azurerm_dns_zone.public["public_one"].tags["Terraform"] == "true"
    error_message = "Default Terraform tag should still be present"
  }

  assert {
    condition     = azurerm_dns_zone.public["public_one"].tags["environment"] == "test"
    error_message = "Custom environment tag should be present"
  }

  assert {
    condition     = azurerm_dns_zone.public["public_one"].tags["team"] == "platform"
    error_message = "Custom team tag should be present"
  }
}

run "caller_can_override_default_tags" {
  command = plan

  variables {
    tags = {
      Terraform = "managed"
    }
  }

  assert {
    condition     = azurerm_dns_zone.public["public_one"].tags["Terraform"] == "managed"
    error_message = "Caller should be able to override the default Terraform tag"
  }
}
