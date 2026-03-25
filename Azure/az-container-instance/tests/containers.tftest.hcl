variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  container_groups = {
    app = {
      name            = "cg-app"
      os_type         = "Linux"
      ip_address_type = "Public"
      dns_name_label  = "cg-app-test"
      containers = {
        web = {
          name   = "nginx"
          image  = "nginx:latest"
          cpu    = 0.5
          memory = 1.0
          ports = [{
            port     = 80
            protocol = "TCP"
          }]
        }
        sidecar = {
          name   = "sidecar"
          image  = "busybox:latest"
          cpu    = 0.25
          memory = 0.5
          commands = ["sh", "-c", "while true; do echo running; sleep 30; done"]
        }
      }
    }
  }
}

run "two_containers" {
  command = plan

  assert {
    condition     = length(azurerm_container_group.this) == 1
    error_message = "Expected exactly one container group."
  }

  assert {
    condition     = azurerm_container_group.this["app"].name == "cg-app"
    error_message = "Container group name should be cg-app."
  }

  assert {
    condition     = azurerm_container_group.this["app"].os_type == "Linux"
    error_message = "Container group os_type should be Linux."
  }

  assert {
    condition     = azurerm_container_group.this["app"].ip_address_type == "Public"
    error_message = "Container group ip_address_type should be Public."
  }
}
