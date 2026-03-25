mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  location            = "eastus2"

  service_plans = {
    test = {
      name     = "plan-test"
      os_type  = "Linux"
      sku_name = "B1"
    }
  }

  web_apps = {
    bad = {
      name             = "app-bad"
      service_plan_key = "test"
      os_type          = "linux"
      https_only       = false
    }
  }
}

run "rejects_https_only_false" {
  command         = plan
  expect_failures = [var.web_apps]
}

run "rejects_tls_below_1_2" {
  command         = plan
  expect_failures = [var.web_apps]

  variables {
    web_apps = {
      bad = {
        name             = "app-bad"
        service_plan_key = "test"
        os_type          = "linux"
        site_config = {
          minimum_tls_version = "1.0"
        }
      }
    }
  }
}

run "rejects_ftp_enabled" {
  command         = plan
  expect_failures = [var.web_apps]

  variables {
    web_apps = {
      bad = {
        name             = "app-bad"
        service_plan_key = "test"
        os_type          = "linux"
        site_config = {
          ftps_state = "AllAllowed"
        }
      }
    }
  }
}

run "rejects_remote_debugging_enabled" {
  command         = plan
  expect_failures = [var.web_apps]

  variables {
    web_apps = {
      bad = {
        name             = "app-bad"
        service_plan_key = "test"
        os_type          = "linux"
        site_config = {
          remote_debugging_enabled = true
        }
      }
    }
  }
}

run "rejects_invalid_os_type" {
  command         = plan
  expect_failures = [var.web_apps]

  variables {
    web_apps = {
      bad = {
        name             = "app-bad"
        service_plan_key = "test"
        os_type          = "macos"
      }
    }
  }
}

run "rejects_invalid_plan_os_type" {
  command         = plan
  expect_failures = [var.service_plans]

  variables {
    service_plans = {
      bad = {
        name     = "plan-bad"
        os_type  = "MacOS"
        sku_name = "B1"
      }
    }
    web_apps = {}
  }
}
