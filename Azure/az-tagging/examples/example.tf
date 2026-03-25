# --------------------------------------------------------------------------
# Example: Using az-tagging to feed consistent tags into other modules
# --------------------------------------------------------------------------

module "tags" {
  source = "../"

  environment         = var.environment
  owner               = var.owner
  cost_center         = var.cost_center
  data_classification = var.data_classification
  project             = var.project

  additional_tags = {
    team       = "platform"
    department = "engineering"
  }
}

# --------------------------------------------------------------------------
# Feed tags into az-virtual-network
# --------------------------------------------------------------------------

module "vnet" {
  source              = "../../az-virtual-network"
  resource_group_name = "rg-${var.project}-${var.environment}"
  location            = "eastus2"

  vnets = {
    main = {
      name          = "vnet-${var.project}-${var.environment}"
      address_space = ["10.0.0.0/16"]
      tags          = module.tags.tags
      subnets = {
        app = {
          address_prefixes = ["10.0.1.0/24"]
        }
        data = {
          address_prefixes = ["10.0.2.0/24"]
        }
      }
    }
  }
}

# --------------------------------------------------------------------------
# Feed tags into az-storage-account
# --------------------------------------------------------------------------

# module "storage" {
#   source              = "../../az-storage-account"
#   resource_group_name = "rg-${var.project}-${var.environment}"
#   location            = "eastus2"
#   name                = "st${var.project}${var.environment}"
#   tags                = module.tags.tags
# }

# --------------------------------------------------------------------------
# Variables for this example
# --------------------------------------------------------------------------

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "cost_center" {
  type    = string
  default = "CC-1234"
}

variable "data_classification" {
  type    = string
  default = "internal"
}

variable "project" {
  type    = string
  default = "landing-zone"
}
