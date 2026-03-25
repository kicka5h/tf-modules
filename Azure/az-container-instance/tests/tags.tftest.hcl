variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  tags = {
    Environment = "test"
  }
  container_groups = {
    app = {
      name            = "cg-tags"
      ip_address_type = "Public"
      containers = {
        main = {
          name   = "nginx"
          image  = "nginx:latest"
          cpu    = 0.5
          memory = 1.0
        }
      }
      tags = {
        Team = "platform"
      }
    }
  }
}

run "default_and_custom_tags" {
  command = plan

  assert {
    condition     = azurerm_container_group.this["app"].tags["Terraform"] == "true"
    error_message = "Default tag Terraform=true must be present."
  }

  assert {
    condition     = azurerm_container_group.this["app"].tags["Environment"] == "test"
    error_message = "Module-level tag Environment=test must be present."
  }

  assert {
    condition     = azurerm_container_group.this["app"].tags["Team"] == "platform"
    error_message = "Per-group tag Team=platform must be present."
  }
}
