terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.14.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
  tenant_id                       = "00000000-0000-0000-0000-000000000000"
  client_id                       = "00000000-0000-0000-0000-000000000000"
  client_secret                   = "mock-secret"
  metadata_host                   = "localhost.localstack.cloud:4566"
  resource_provider_registrations = "none"
}

