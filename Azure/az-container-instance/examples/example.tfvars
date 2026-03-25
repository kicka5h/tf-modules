resource_group_name = "rg-containers"
location            = "eastus2"

container_groups = {
  web = {
    name            = "cg-web"
    os_type         = "Linux"
    restart_policy  = "Always"
    ip_address_type = "Private"
    subnet_ids      = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-networking/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/snet-containers"]

    containers = {
      nginx = {
        name   = "nginx"
        image  = "nginx:1.25"
        cpu    = 0.5
        memory = 1.0
        ports = [{
          port     = 80
          protocol = "TCP"
        }]
        environment_variables = {
          NGINX_PORT = "80"
        }
      }
      sidecar = {
        name   = "log-collector"
        image  = "fluent/fluent-bit:latest"
        cpu    = 0.25
        memory = 0.5
        environment_variables = {
          FLUENT_OUTPUT = "stdout"
        }
        volume = [{
          name       = "shared-logs"
          mount_path = "/var/log/nginx"
          read_only  = true
        }]
      }
    }

    dns_config = {
      nameservers = ["10.0.0.4", "10.0.0.5"]
    }

    tags = {
      App = "web-frontend"
    }
  }
}

tags = {
  Environment = "production"
  Team        = "platform"
}
