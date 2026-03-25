variables {
  resource_group_name = "rg-test"
  location            = "eastus2"
  container_groups = {
    bad = {
      name    = "cg-bad"
      os_type = "FreeBSD"
      containers = {
        main = {
          name   = "nginx"
          image  = "nginx:latest"
          cpu    = 0.5
          memory = 1.0
        }
      }
    }
  }
}

run "invalid_os_type" {
  command = plan

  expect_failures = [
    var.container_groups,
  ]
}
